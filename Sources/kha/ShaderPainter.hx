package kha;

import kha.graphics.ConstantLocation;
import kha.graphics.IndexBuffer;
import kha.graphics.Program;
import kha.graphics.Texture;
import kha.graphics.TextureUnit;
import kha.graphics.VertexBuffer;
import kha.graphics.VertexData;
import kha.graphics.VertexStructure;

class ImageShaderPainter {
	private var projectionMatrix: Array<Float>;
	private var shaderProgram: Program;
	private var structure: VertexStructure;
	private var projectionLocation: ConstantLocation;
	private var textureLocation: TextureUnit;
	private static var bufferSize: Int = 100;
	private var bufferIndex: Int;
	private var rectVertexBuffer: VertexBuffer;
    private var rectVertices: Array<Float>;
	private var indexBuffer: IndexBuffer;
	private var lastTexture: Texture;

	public function new(projectionMatrix: Array<Float>) {
		this.projectionMatrix = projectionMatrix;
		initShaders();
		initBuffers();
		projectionLocation = shaderProgram.getConstantLocation("projectionMatrix");
		textureLocation = shaderProgram.getTextureUnit("tex");
	}
	
	private function initShaders(): Void {
		var fragmentShader = Sys.graphics.createFragmentShader(Loader.the.getShader("painter-image.frag"));
		var vertexShader = Sys.graphics.createVertexShader(Loader.the.getShader("painter-image.vert"));
	
		shaderProgram = Sys.graphics.createProgram();
		shaderProgram.setFragmentShader(fragmentShader);
		shaderProgram.setVertexShader(vertexShader);

		structure = new VertexStructure();
		structure.add("vertexPosition", VertexData.Float3);
		structure.add("texPosition", VertexData.Float2);
		
		shaderProgram.link(structure);
	}
	
	function initBuffers(): Void {
		rectVertexBuffer = Sys.graphics.createVertexBuffer(bufferSize * 4, structure);
		rectVertices = rectVertexBuffer.lock();
		
		indexBuffer = Sys.graphics.createIndexBuffer(bufferSize * 3 * 2);
		var indices = indexBuffer.lock();
		for (i in 0...bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		indexBuffer.unlock();
	}
	
	private function setRectVertices(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 5 * 4;
		rectVertices[baseIndex +  0] = left;
		rectVertices[baseIndex +  1] = bottom;
		rectVertices[baseIndex +  2] = -5.0;
		
		rectVertices[baseIndex +  5] = left;
		rectVertices[baseIndex +  6] = top;
		rectVertices[baseIndex +  7] = -5.0;
		
		rectVertices[baseIndex + 10] = right;
		rectVertices[baseIndex + 11] = top;
		rectVertices[baseIndex + 12] = -5.0;
		
		rectVertices[baseIndex + 15] = right;
		rectVertices[baseIndex + 16] = bottom;
		rectVertices[baseIndex + 17] = -5.0;
	}
	
	private function setRectTexCoords(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 5 * 4;
		rectVertices[baseIndex +  3] = left;
		rectVertices[baseIndex +  4] = bottom;
		
		rectVertices[baseIndex +  8] = left;
		rectVertices[baseIndex +  9] = top;
		
		rectVertices[baseIndex + 13] = right;
		rectVertices[baseIndex + 14] = top;
		
		rectVertices[baseIndex + 18] = right;
		rectVertices[baseIndex + 19] = bottom;
	}

	private function setTexture(img: Image): Void {
		Sys.graphics.setTexture(textureLocation, img);
	}
	
	private function drawBuffer(): Void {
		setTexture(lastTexture);
		
		rectVertexBuffer.unlock();
		Sys.graphics.setVertexBuffer(rectVertexBuffer);
		Sys.graphics.setIndexBuffer(indexBuffer);
		Sys.graphics.setProgram(shaderProgram);
		Sys.graphics.setMatrix(projectionLocation, projectionMatrix);
		
		Sys.graphics.drawIndexedVertices(0, bufferIndex * 2 * 3);

		bufferIndex = 0;
	}
	
	public function drawImage(img: kha.Image, x: Float, y: Float): Void {
		var tex = cast(img, Texture);
		if (bufferIndex + 1 >= bufferSize || (lastTexture != null && tex != lastTexture)) drawBuffer();
		
		var left: Float = x;
		var top: Float = y;
		var right: Float = x + img.width;
		var bottom: Float = y + img.height;
		
		setRectTexCoords(0, 0, tex.width / tex.realWidth, tex.height / tex.realHeight);
		setRectVertices(left, top, right, bottom);
		++bufferIndex;
		lastTexture = tex;
	}
	
	public function drawImage2(img: kha.Image, sx: Float, sy: Float, sw: Float, sh: Float, dx: Float, dy: Float, dw: Float, dh: Float): Void {
		var tex = cast(img, Texture);
		if (bufferIndex + 1 >= bufferSize || (lastTexture != null && tex != lastTexture)) drawBuffer();
		
		var left: Float = dx;
		var top: Float = dy;
		var right: Float = dx + dw;
		var bottom: Float = dy + dh;
		
		setRectTexCoords(sx / tex.realWidth, sy / tex.realHeight, (sx + sw) / tex.realWidth, (sy + sh) / tex.realHeight);
		setRectVertices(left, top, right, bottom);
		++bufferIndex;
		lastTexture = tex;
	}
	
	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
		lastTexture = null;
	}
}

class ColoredShaderPainter {
	private var projectionMatrix: Array<Float>;
	private var shaderProgram: Program;
	private var structure: VertexStructure;
	private var projectionLocation: ConstantLocation;
	private static var bufferSize: Int = 100;
	private var bufferIndex: Int;
	private var rectVertexBuffer: VertexBuffer;
    private var rectVertices: Array<Float>;
	private var indexBuffer: IndexBuffer;

	public function new(projectionMatrix: Array<Float>) {
		this.projectionMatrix = projectionMatrix;
	}
	
	public function end(): Void {
		//if (bufferIndex > 0) drawBuffer();
	}
}

class TextShaderPainter {
	private var projectionMatrix: Array<Float>;
	private var shaderProgram: Program;
	private var structure: VertexStructure;
	private var projectionLocation: ConstantLocation;
	private var textureLocation: TextureUnit;
	private static var bufferSize: Int = 100;
	private var bufferIndex: Int;
	private var rectVertexBuffer: VertexBuffer;
    private var rectVertices: Array<Float>;
	private var indexBuffer: IndexBuffer;
	private var font: Kravur;
	private var lastTexture: Texture;
	
	public function new(projectionMatrix: Array<Float>) {
		this.projectionMatrix = projectionMatrix;
		initShaders();
		initBuffers();
		projectionLocation = shaderProgram.getConstantLocation("projectionMatrix");
		textureLocation = shaderProgram.getTextureUnit("tex");
	}
	
	private function initShaders(): Void {
		var fragmentShader = Sys.graphics.createFragmentShader(Loader.the.getShader("painter-image.frag"));
		var vertexShader = Sys.graphics.createVertexShader(Loader.the.getShader("painter-image.vert"));
	
		shaderProgram = Sys.graphics.createProgram();
		shaderProgram.setFragmentShader(fragmentShader);
		shaderProgram.setVertexShader(vertexShader);

		structure = new VertexStructure();
		structure.add("vertexPosition", VertexData.Float3);
		structure.add("texPosition", VertexData.Float2);
		
		shaderProgram.link(structure);
	}
	
	function initBuffers(): Void {
		rectVertexBuffer = Sys.graphics.createVertexBuffer(bufferSize * 4, structure);
		rectVertices = rectVertexBuffer.lock();
		
		indexBuffer = Sys.graphics.createIndexBuffer(bufferSize * 3 * 2);
		var indices = indexBuffer.lock();
		for (i in 0...bufferSize) {
			indices[i * 3 * 2 + 0] = i * 4 + 0;
			indices[i * 3 * 2 + 1] = i * 4 + 1;
			indices[i * 3 * 2 + 2] = i * 4 + 2;
			indices[i * 3 * 2 + 3] = i * 4 + 0;
			indices[i * 3 * 2 + 4] = i * 4 + 2;
			indices[i * 3 * 2 + 5] = i * 4 + 3;
		}
		indexBuffer.unlock();
	}
	
	private function setRectVertices(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 5 * 4;
		rectVertices[baseIndex +  0] = left;
		rectVertices[baseIndex +  1] = bottom;
		rectVertices[baseIndex +  2] = -5.0;
		
		rectVertices[baseIndex +  5] = left;
		rectVertices[baseIndex +  6] = top;
		rectVertices[baseIndex +  7] = -5.0;
		
		rectVertices[baseIndex + 10] = right;
		rectVertices[baseIndex + 11] = top;
		rectVertices[baseIndex + 12] = -5.0;
		
		rectVertices[baseIndex + 15] = right;
		rectVertices[baseIndex + 16] = bottom;
		rectVertices[baseIndex + 17] = -5.0;
	}
	
	private function setRectTexCoords(left: Float, top: Float, right: Float, bottom: Float): Void {
		var baseIndex: Int = bufferIndex * 5 * 4;
		rectVertices[baseIndex +  3] = left;
		rectVertices[baseIndex +  4] = bottom;
		
		rectVertices[baseIndex +  8] = left;
		rectVertices[baseIndex +  9] = top;
		
		rectVertices[baseIndex + 13] = right;
		rectVertices[baseIndex + 14] = top;
		
		rectVertices[baseIndex + 18] = right;
		rectVertices[baseIndex + 19] = bottom;
	}

	private function setTexture(img: Image): Void {
		Sys.graphics.setTexture(textureLocation, img);
	}
	
	private function drawBuffer(): Void {
		setTexture(lastTexture);
		
		rectVertexBuffer.unlock();
		Sys.graphics.setVertexBuffer(rectVertexBuffer);
		Sys.graphics.setIndexBuffer(indexBuffer);
		Sys.graphics.setProgram(shaderProgram);
		Sys.graphics.setMatrix(projectionLocation, projectionMatrix);
		
		Sys.graphics.drawIndexedVertices(0, bufferIndex * 2 * 3);

		bufferIndex = 0;
	}
	
	public function setFont(font: Font): Void {
		this.font = cast(font, Kravur);
	}
	
	public function drawString(text: String, x: Float, y: Float): Void {
		var tex = font.getTexture();
		if (bufferIndex + 1 >= bufferSize || (lastTexture != null && tex != lastTexture)) drawBuffer();

		var xpos = x;
		var ypos = y;
		for (i in 0...text.length) {
			var q = font.getBakedQuad(text.charCodeAt(i) - 32, xpos, ypos);
			setRectTexCoords(q.s0 * tex.width / tex.realWidth, q.t0 * tex.height / tex.realHeight, q.s1 * tex.width / tex.realWidth, q.t1 * tex.height / tex.realHeight);
			setRectVertices(q.x0, q.y0, q.x1, q.y1);
			xpos += q.xadvance;
			++bufferIndex;
		}
		lastTexture = tex;
	}
	
	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
		lastTexture = null;
	}
}

class ShaderPainter extends Painter {
	private var tx: Float = 0;
	private var ty: Float = 0;
	private var projectionMatrix: Array<Float>;
	private var imagePainter: ImageShaderPainter;
	private var coloredPainter: ColoredShaderPainter;
	private var textPainter: TextShaderPainter;
	
	public function new(width: Int, height: Int) {
		setScreenSize(width, height);
		imagePainter = new ImageShaderPainter(projectionMatrix);
		coloredPainter = new ColoredShaderPainter(projectionMatrix);
		textPainter = new TextShaderPainter(projectionMatrix);
	}
	
	public function setScreenSize(width: Int, height: Int) {
		projectionMatrix = ortho(0, width, height, 0, 0.1, 1000);
	}
	
	private function ortho(left: Float, right: Float, bottom: Float, top: Float, zn: Float, zf: Float): Array<Float> {
		var tx: Float = -(right + left) / (right - left);
		var ty: Float = -(top + bottom) / (top - bottom);
		var tz: Float = -(zf + zn) / (zf - zn);
		//var tz : Float = -zn / (zf - zn);
		return [
			2 / (right - left), 0,                  0,              0,
			0,                  2 / (top - bottom), 0,              0,
			0,                  0,                  -2 / (zf - zn), 0,
			tx,                 ty,                 tz,             1
		];
	}
	
	public override function drawImage(img: kha.Image, x: Float, y: Float): Void {
		coloredPainter.end();
		textPainter.end();
		imagePainter.drawImage(img, tx + x, ty + y);
	}
	
	public override function drawImage2(img: kha.Image, sx: Float, sy: Float, sw: Float, sh: Float, dx: Float, dy: Float, dw: Float, dh: Float): Void {
		coloredPainter.end();
		textPainter.end();
		imagePainter.drawImage2(img, sx, sy, sw, sh, tx + dx, ty + dy, dw, dh);
	}
	
	public override function setColor(r: Int, g: Int, b: Int): Void {
		//context.setStrokeStyle(CssColor.make(r, g, b));
		//context.setFillStyle(CssColor.make(r, g, b));
	}
	
	public override function drawRect(x: Float, y: Float, width: Float, height: Float): Void {
		//context.rect(tx + x, ty + y, width, height);
	}
	
	public override function fillRect(x: Float, y: Float, width: Float, height: Float): Void {
		//context.fillRect(tx + x, ty + y, width, height);
	}

	public override function translate(x: Float, y: Float) {
		tx = x;
		ty = y;
	}

	public override function drawString(text: String, x: Float, y: Float): Void {
		imagePainter.end();
		coloredPainter.end();
		textPainter.drawString(text, tx + x, ty + y);
	}

	public override function setFont(font: Font): Void {
		textPainter.setFont(font);
	}

	public override function drawLine(x1: Float, y1: Float, x2: Float, y2: Float): Void {
		/*context.moveTo(tx + x1, ty + y1);
		context.lineTo(tx + x2, ty + y2);
		context.moveTo(0, 0);*/
	}

	public override function fillTriangle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
		/*context.beginPath();
		
		context.closePath();
		context.fill();*/
	}
	
	public override function begin(): Void {
		Sys.graphics.clear(kha.Color.fromBytes(0, 0, 0));
		translate(0, 0);
	}
	
	public override function end(): Void {
		imagePainter.end();
		coloredPainter.end();
		textPainter.end();
	}
}
