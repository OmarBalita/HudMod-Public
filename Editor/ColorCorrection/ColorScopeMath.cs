using Godot;
using Godot.Collections;

[GlobalClass]
// calculate func made by Omar Top, and optimized by Gemini with rawData Awsome Idea !!
public partial class ColorScopeMath : GodotObject
{
	static Dictionary<StringName, Variant> Calculate(Image inputAsImage, byte[] rawData, int samplesDownScale)
	{
		int width = inputAsImage.GetWidth();
		int height = inputAsImage.GetHeight();

		int channels = rawData.Length / (width * height);

		int widthDS = width / samplesDownScale;
		int heightDS = height / samplesDownScale;
		float pixelOpacity = 0.03f * samplesDownScale;

		Vector4[] hData = new Vector4[256];
		Vector4[,] wData = new Vector4[widthDS, 256];

		for (int xStep = 0; xStep < widthDS; xStep++)
		{
			int x = xStep * samplesDownScale;

			for (int yStep = 0; yStep < heightDS; yStep++)
			{
				int y = yStep * samplesDownScale;

				int idx = (y * width + x) * channels;

				int r = rawData[idx];
				int g = rawData[idx + 1];
				int b = rawData[idx + 2];
				int lum = (int)(r * 0.299f + g * 0.587f + b * 0.114f);

				hData[r].X += 1;
				hData[g].Y += 1;
				hData[b].Z += 1;
				hData[lum].W += 1;
				
				wData[xStep, r].X += pixelOpacity;
				wData[xStep, g].Y += pixelOpacity;
				wData[xStep, b].Z += pixelOpacity;
				wData[xStep, lum].W += pixelOpacity;
			}
		}

		Image rImg = Image.CreateEmpty(widthDS, 256, false, Image.Format.La8);
		Image gImg = Image.CreateEmpty(widthDS, 256, false, Image.Format.La8);
		Image bImg = Image.CreateEmpty(widthDS, 256, false, Image.Format.La8);
		Image lImg = Image.CreateEmpty(widthDS, 256, false, Image.Format.La8);

		for (int x = 0; x < widthDS; x++)
		{
			for (int y = 0; y < 256; y++)
			{
				Vector4 val = wData[x, y];
				int invY = 255 - y;

				rImg.SetPixel(x, invY, new Color(1, 1, 1, val.X));
				gImg.SetPixel(x, invY, new Color(1, 1, 1, val.Y));
				bImg.SetPixel(x, invY, new Color(1, 1, 1, val.Z));
				lImg.SetPixel(x, invY, new Color(1, 1, 1, val.W));
			}
		}
		
		return new()
		{
			{ "resolution", new Vector2I(width, height) },
			{ "histogram", histogramToDict(hData) },
			{ "waveform", WaveformToDict(wData, widthDS) },
			{ "r_img", ImageTexture.CreateFromImage(rImg) },
			{ "g_img", ImageTexture.CreateFromImage(gImg) },
			{ "b_img", ImageTexture.CreateFromImage(bImg) },
			{ "lum_img", ImageTexture.CreateFromImage(lImg) }
		};
	}
	
	private static Array<Vector4> histogramToDict(Vector4[] csharpArray)
    {
        var gArray = new Array<Vector4>();
        gArray.Resize(csharpArray.Length);
        for (int i = 0; i < csharpArray.Length; i++) gArray[i] = csharpArray[i];
        return gArray;
	}

    private static Dictionary<int, Array<Vector4>> WaveformToDict(Vector4[,] wData, int widthDS)
    {
        var dict = new Dictionary<int, Array<Vector4>>();
        for (int x = 0; x < widthDS; x++)
        {
            var column = new Array<Vector4>();
            column.Resize(256);
            for (int y = 0; y < 256; y++) column[y] = wData[x, y];
            dict.Add(x, column);
        }
        return dict;
    }
}
