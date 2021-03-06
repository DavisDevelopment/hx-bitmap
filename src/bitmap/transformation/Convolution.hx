package bitmap.transformation;

import bitmap.*;

typedef ConvolveOptions = {
	> Transform.TransformationOptions,
	public var kernel:Array<Array<Float>>;
	@:optional public var bias:Float;
	@:optional public var factor:Float;
}

class Convolution {
	public static function convolve(o:ConvolveOptions) {
		Sure.sure(o.bitmap != o.output);
		Sure.sure(o.output == null || o.bitmap.width == o.output.width && o.bitmap.height == o.output.height);
		var output = o.output == null ? o.bitmap.clone() : o.output;
		var data = o.bitmap, width = o.bitmap.width, height = o.bitmap.height, matrix = o.kernel;
		var w = matrix[0].length, h = matrix.length, half = Math.floor(h / 2);
		var factor = o.factor == null ? 1.0 : o.factor, bias = o.bias == null ? 0.0 : o.bias;
		var region = o.region == null ? output.bounds()			: o.region;
		for (y in region.y...region.height) {
			for (x in region.x...region.width) {
				// var px = (y * width + x) * 4;
        var px = (width * y + x) << 2 ;
				var r = 0.0, g = 0.0, b = 0.0;
				for (cy in 0...h) {
					for (cx in 0...w) {
						// HEADS UP: we need to be very strict on types for static targets.
						// Not only cpx index but also Null<Int> (nullability).
						// See https://haxe.org/manual/types-nullability.html
						var cpx = Math.floor(((y + (cy - half)) * width + (x + (cx - half))) * 4);
						var ir:Null<Int> = cpx >= 0 && cpx < data.data.length ? data.data.get(cpx + 0) : 0;
						var ig:Null<Int> = cpx >= 0 && cpx + 1 < data.data.length ? data.data.get(cpx + 1) : 0;
						var ib:Null<Int> = cpx >= 0 && cpx + 2 < data.data.length ? data.data.get(cpx + 2) : 0;
						ir = ir == null ? 0 : ir;
						ig = ig == null ? 0 : ig;
						ib = ib == null ? 0 : ib;
						r += ir * matrix[cy][cx];
						g += ig * matrix[cy][cx];
						b += ib * matrix[cy][cx];
					}
				}
				output.data.set(px + 0, Util.clamp(Math.round(factor * r + bias), 0, 255));
				output.data.set(px + 1, Util.clamp(Math.round(factor * g + bias), 0, 255));
				output.data.set(px + 2, Util.clamp(Math.round(factor * b + bias), 0, 255));
				output.data.set(px + 3, data.data.get(px + 3));
			}
		}
		return output;
	}

	public static function blur(size:Int = 3, bias:Float = 0.0,  ?output:Bitmap) {
		return {
			kernel: blurKernel(size, bias),
			bias: bias,
			factor: 1 / (size * size),
			bitmap: null,
			output: output,
			region: null
		};
	}
	public static function blurKernel(size:Int = 3, bias:Float = 0.0) {
		var k = [for (i in 0...size) [for (i in 0...size) 0.0]];
		for (i in 0...size)
			for (j in 0...size)
				k[i][j] = 1.0;
        return k;
  }
	/**
		1, 1, 1, 1, 1,
			1, 0, 0, 0, 1,
			1, 0, 0, 0, 1,
			1, 0, 0, 0, 1,
			1, 1, 1, 1, 1,
	**/
	public static function fBlur(size:Int = 4, bias:Float = 0.0,  ?output:Bitmap) {
		var k = [for (i in 0...size) [for (i in 0...size) 0.0]];
		for (i in 0...size)
			for (j in 0...size)
				if (i == 0 || j == 0 || i == size - 1 || j == size - 1)
					k[i][j] = 1.0;
				else
					k[i][j] = 0;
		return {
			kernel: k,
			bias: bias,
			factor: 1 / (size + 1),
			bitmap: null,
			output: output,
			region: null
		};
	}

	public static function sharp(factor = 1.0, bias:Float = 0.0, ?output:Bitmap) {
		var k = [
			[-1 / 9.0, -1 / 9.0, -1 / 9.0, -1 / 9.0],
			[-1 / 9.0, factor, factor, -1 / 9.0],
			[-1 / 9.0, factor, factor, -1 / 9.0],
			[-1 / 9.0, -1 / 9.0, -1 / 9.0, -1 / 9.0]
		];
		return {
			kernel: k,
			bias: bias,
			factor: factor,
			bitmap: null,
			output: output,
			region: null
		};
	}
}
