function recipes(ev) {
	ev.remove({output: 'tempad:tempad'})
	ev.shaped('tempad:tempad', [
		'GGG',
		'PCD',
		'GGG'
	], {
		G: 'minecraft:gold_ingot',
		P: 'modern_industrialization:processing_unit',
		C: 'powah:ender_core',
		D: 'techreborn:digital_display'
	})
	ev.shaped('tempad:he_who_remains_tempad', [
		'UTD',
		'NSN',
		'DRU'
	], {
		U: 'dimdoors:unravelled_block', 
		N: 'minecraft:netherite_ingot',
		D: 'minecraft:deepslate',
		T: 'tempad:tempad',
		R: 'blockus:legacy_nether_reactor_core',
		S: 'minecraft:nether_star'
	})
}

onEvent("recipes", recipes);
