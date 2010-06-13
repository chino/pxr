require "binreader"
require "vector"
require 'pickup'
class FsknPic
	@@names = [
		'Trojax',
		'Pyrolite',
		'Transpulse',
		'SussGun',
		'Laser',
		'Mug',
		'Mugs',
		'Heatseaker',
		'HeatseakerPickup',
		'Thief',
		'Scatter',
		'Gravgon',
		'Launcher',
		'TitanStar',
		'PurgePickup',
		'PinePickup',
		'QuantumPickup',
		'SpiderPod',
		'Parasite',
		'Flare',
		'GeneralAmmo',
		'PyroliteAmmo',
		'SussGunAmmo',
		'PowerPod',
		'Shield',
		'Inv',
		'ExtraLife',
		'Computer',
		'Smoke',
		'Nitro',
		'Goggles',
		'Gold',
		'Mantle',
		'Crystal',
		'Orb',
		'GoldenPowerPod',
		'DNA',
		'SkeletonKey',
		'Bomb',
		'GoldFigure',
		'Flag',
		'Bounty',
		'Flag1',
		'Flag2',
		'Flag3',
		'Flag4'
	]
	@@files = [
		'troj.mx',
		'prlt.mx',
		'trans.mx',
		'sus.mx',
		'beam.mx',
		'mug.mx',
		'mugs.mx',
		'heat.mx',
		'heatpk.mx',
		'thef.mx',
		'sctr.mx',
		'grav.mx',
		'lnch.mx',
		'titan.mx',
		'prgpod.mx',
		'pine.mx',
		'qpod.mx',
		'spdpod.mx',
		'para.mx',
		'flar.mx',
		'nrg.mx',
		'fuel.mx',
		'ammo.mx',
		'pod.mx',
		'shld.mx',
		'vuln.mx',
		'xtra.mx',
		'comp.mx',
		'smok.mx',
		'ntro.mx',
		'gogl.mx',
		'gold.mx',
		'mant.mx',
		'crys.mx',
		'orb.mx',
		'gpod.mx',
		'dna.mx',
		'key.mx',
		'bomb.mx',
		'goldfig.mx',
		'flagmrphwave000.mxa',
		'gold.mx',
		'redflagwave000.mxa',
		'greenflagwave000.mxa',
		'blueflagwave000.mxa',
		'yellowflagwave000.mxa'
	]
	attr_accessor :filename, :level, :version, :pickups
	include BinReader
	def read_vector
		Vector.new( -read_float, read_float, read_float )
	end
	def initialize file
		@filename = file
		@level = File.basename file
		open file
		throw "not a ProjectX file" if read(4) != 'PRJX'
		@version = read_int
		npickups = read_short
		@pickups = []
		npickups.times {
			props = {
				:gentype    => read_short,
				:regentype  => read_short,
				:gendelay   => read_float,
				:lifespan   => read_float,
				:pos        => read_vector,
				:group      => read_short,
				:pickup     => read_short,
				:triggermod => read_short
			}
			props[:file] = @@files[props[:pickup]]
			props[:name] = @@names[props[:pickup]]
			p = Pickup.new({
				:file => props[:file],
				:body => Physics::SphereBody.new({
					:pos => props[:pos],
					:rotation_drag => 0,
					:rotation_velocity => Vector.new(1,1,1)
				})
			})
			props.delete :pos
			props.keys.each do |prop|
				p.instance_variable_set(
					"@#{prop}".to_sym,
					props[prop] 
				)
			end
			@pickups << p
		}
		read_close
	end
	def save file
		f = File.new file, 'w'
		f.write "PRJX"
		f.write [@version, @pickups.count].pack "iv"
		@pickups.each { |p| f.write p.serialize }
		f.close
	end
end
