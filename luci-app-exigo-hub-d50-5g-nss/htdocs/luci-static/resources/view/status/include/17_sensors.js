'use strict';
'require baseclass';
'require fs';

document.head.append(E('style', {'type': 'text/css'},
`
.sensors-area {
	margin-bottom: 1em;
}
.sensors-label {
	display: inline-block;
	vertical-align: top;
	word-wrap: break-word;
	padding: 4px 8px;
	width: 12em;
}
.sensors-label-auto {
	width: auto;
}
.sensors-label-title {
	display: block;
	word-wrap: break-word;
	width: 100%;
	font-weight: bold;
}
.sensors-label-value {
	display: block;
	word-wrap: break-word;
	width: 100%;
}
.sensors-empty-area {
	width: 100%;
	text-align: center;
}

`))

return baseclass.extend({
	title      : _('Sensors'),

	tempFormat(temp) {
		if(!temp && temp !== 0) {
			return '-';
		};
		return Number(temp.toFixed(1)) + ' °C';
	},

	loadSensors() {
		return L.resolveDefault(
			fs.exec('/usr/share/xunison/sensors.sh').then(res => {
				if(res.code === 0) {
					try {
						return JSON.parse(res.stdout);
					} catch(e) {
						return null;
					}
				}
				return null;
			}),
			null
		);
	},

	// CPU frequency per core
	loadCpuFreq() {
		const reads = [];
		for(let n = 0; n < 8; n++) {
			reads.push(
				L.resolveDefault(
					fs.read(`/sys/devices/system/cpu/cpu${n}/cpufreq/scaling_cur_freq`),
					null
				).then(v => (v == null) ? null : { number: n, freq: parseInt(v, 10) })
			);
		};
		return Promise.all(reads).then(list => list.filter(c => c && !isNaN(c.freq)));
	},

	loadNssLoad() {
		return L.resolveDefault(
			fs.lines('/sys/kernel/debug/qca-nss-drv/stats/cpu_load_ubi').then(lines => {
				const statLine = lines.find(line => line.includes('%'));
				if(statLine) {
					const [min, avg, max] = statLine.trim().split(/\s+/);
					return { min, avg, max };
				}
				return null;
			}),
			null
		);
	},

	// ECM accelerated connections (IPv4 / IPv6)
	loadEcm() {
		return Promise.all([
			L.resolveDefault(fs.read('/sys/kernel/debug/ecm/ecm_nss_ipv4/accelerated_count'), null),
			L.resolveDefault(fs.read('/sys/kernel/debug/ecm/ecm_nss_ipv6/accelerated_count'), null),
		]).then(([ip4, ip6]) => {
			if(ip4 == null) {
				return null;
			}
			return {
				ip4: String(ip4).trim(),
				ip6: String(ip6 || '0').trim(),
			};
		});
	},

	freqFormat(freq) {
		if(!freq) {
			return '-';
		};
		return (freq >= 1e6) ?
			Number((freq / 1e6).toFixed(3)) + ' ' + _('GHz')
		:
			Number((freq / 1e3).toFixed(3)) + ' ' + _('MHz');
	},

	load() {
		return Promise.all([
			this.loadSensors(),
			this.loadNssLoad(),
			this.loadEcm(),
			this.loadCpuFreq(),
		]);
	},

	sensorLabels: {
		'CPU':                 'CPU',
		'Mainboard':           'Mainboard',
		'Network Coprocessor': 'Network Coprocessor',
		'Ethernet':            'Ethernet',
		'Wi-Fi 2.4GHz':         'Wi-Fi 2.4GHz',
		'Wi-Fi 5GHz':           'Wi-Fi 5GHz',
	},

	sensorOrder: [
		'CPU',
		'Mainboard',
		'Ethernet',
		'Network Coprocessor',
		'Wi-Fi 2.4GHz',
		'Wi-Fi 5GHz',
	],

	getSensorLabel(sensor) {
		const key = sensor.description || sensor.name;
		return key in this.sensorLabels ? _(this.sensorLabels[key]) : key;
	},

	render(data) {
		if(!data) {
			return;
		};

		const [sensorsData, nssLoad, ecm, cpuFreq] = data;

		let sensorsArea = E('div', { 'class': 'sensors-area' });

		if(sensorsData && sensorsData.temperatures && Array.isArray(sensorsData.temperatures)) {
			let sortedSensors = [...sensorsData.temperatures].sort((a, b) => {
				const keyA = a.description || a.name;
				const keyB = b.description || b.name;
				const indexA = this.sensorOrder.indexOf(keyA);
				const indexB = this.sensorOrder.indexOf(keyB);
				
				if(indexA === -1 && indexB === -1) return 0;
				if(indexA === -1) return 1;
				if(indexB === -1) return -1;
				
				return indexA - indexB;
			});

			for(let sensor of sortedSensors) {
				if(sensor.temperature_c !== undefined) {
					sensorsArea.append(
						E('div', { 'class': 'sensors-label' }, [
							E('span', { 'class': 'sensors-label-title' },
								this.getSensorLabel(sensor)
							),
							E('span', { 'class': 'sensors-label-value' },
								this.tempFormat(sensor.temperature_c)
							),
						])
					);
				};
			};
		};

		// CPU frequency per core
		let cpuRow = E('div', { 'class': 'sensors-cpu-area' });

		if(Array.isArray(cpuFreq)) {
			for(let c of cpuFreq) {
				cpuRow.append(
					E('div', { 'class': 'sensors-label' }, [
						E('span', { 'class': 'sensors-label-title' },
							_('CPU') + ' ' + c.number + ':'
						),
						E('span', { 'class': 'sensors-label-value' },
							this.freqFormat(c.freq)
						),
					])
				);
			};
		};

		if(cpuRow.childNodes.length > 0) {
			sensorsArea.append(cpuRow);
		};

		if(sensorsArea.childNodes.length == 0){
			sensorsArea.append(
				E('div', { 'class': 'sensors-empty-area' },
					E('em', {}, _('No data...'))
				)
			);
		};

		// NSS Offload
		let nssArea = E('div', { 'class': 'sensors-area' });

		if(nssLoad) {
			nssArea.append(
				E('div', {
					'class': 'sensors-label sensors-label-auto',
					'title': 'Qualcomm NSS (Network Subsystem) is a dedicated hardware offloading engine integrated into Qualcomm IPQ network processors (e.g. IPQ806x, IPQ6018, IPQ807x) used in home and professional routers.'
				}, [
					E('span', { 'class': 'sensors-label-title' },
						_('NSS Core Load')
					),
					E('span', { 'class': 'sensors-label-value' },
						`${_('min.:')} ${nssLoad.min} ${_('avg.:')} ${nssLoad.avg} ${_('max.:')} ${nssLoad.max}`
					),
				])
			);
		};

		// ECM accelerated connections (IP4 / IP6)
		if(ecm) {
			nssArea.append(
				E('div', { 'class': 'sensors-label sensors-label-auto' }, [
					E('span', { 'class': 'sensors-label-title' },
						_('ECM accelerated connections')
					),
					E('span', { 'class': 'sensors-label-value' },
						`${_('IP4:')} ${ecm.ip4} ${_('IP6:')} ${ecm.ip6}`
					),
				])
			);
		};

		if(nssArea.childNodes.length == 0){
			nssArea.append(
				E('div', { 'class': 'sensors-empty-area' },
					E('em', {}, _('No data...'))
				)
			);
		};

		return E([
			sensorsArea,
			E('h3', {}, _('NSS Offload')),
			nssArea,
		]);
	},
});
