using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Channels;

[GlobalClass]
public partial class MediaHelper : GodotObject
{

	public static Gradient waveformGradient = default;

	public static Gradient GetWaveformGradient() {return waveformGradient;}
	public static void SetWaveformGradient(Gradient newVal) {waveformGradient = newVal;}

    private static Dictionary<AudioStreamWav, byte[]> streamsData = new();

    static void PushStreamData(AudioStreamWav stream)
    {
        streamsData.TryAdd(stream, stream.Data);
    }
    static void FreeStreamData(AudioStreamWav stream)
    {
        streamsData.Remove(stream);
    }

    public static Image GenerateWaveformImage(AudioStreamWav stream, double secondFrom, double secondTo, Image.Format imageFormat, int width, int height, int spaceWidth, int lineWidth, int drawMethodIDX = 0, Color bgColor = default)
    {

        DrawWaveformAction drawMethod = drawMethodIDX == 0 ? DrawWaveformLineThumbnail : DrawWaveformLineTimeline;

        Image image = Image.CreateEmpty(width, height, false, imageFormat);
        image.Fill(bgColor);

        byte[] data = streamsData[stream];
        int channels = stream.Stereo ? 2 : 1;
        int sampleRate = stream.MixRate;
        int bytesPerSample = 2;
        int bytesPerFrame = bytesPerSample * channels;

        double length = stream.GetLength();
        secondTo = secondTo < length ? secondTo : length;
        double duration = secondTo - secondFrom;

        int startSample = (int)(secondFrom * sampleRate);
        int startByte = startSample * bytesPerFrame;

        int totalSamples = (int)(duration * sampleRate);
        int samplesPerPixel = totalSamples / width;
        if (samplesPerPixel < 1) samplesPerPixel = 1;

        int stepWidth = spaceWidth + lineWidth;
        int linesCount = width / stepWidth;

        int totalAudioBytes = data.Length;

        int samplesStep = 1;
        if (samplesPerPixel > 100_000) samplesStep = 20_000;
        else if (samplesPerPixel > 10_000) samplesStep = 1_500;
        else if (samplesPerPixel > 1000) samplesStep = 100;
        else if (samplesPerPixel > 100) samplesStep = 5;
        else if (samplesPerPixel > 10) samplesStep = 2;

        int baseStartSampleIdx = startByte / bytesPerSample;

        List<float> amplitudes = [];

        for (int x = 0; x < linesCount; x++)
        {

            int pixelX = x * stepWidth;
            
            int currSampleIdx = baseStartSampleIdx + (pixelX * samplesPerPixel * channels);
            int endSampleIdx = currSampleIdx + (samplesPerPixel * channels);

            float maxAmplitude = .0f;

            if (channels == 1)
            {
                for (int s = currSampleIdx; s < endSampleIdx - 1; s += samplesStep)
                {
                    int byteIdx = s * 2;

                    short sampleValueShort = (short)(data[byteIdx] | (data[byteIdx + 1] << 8));
                    
                    float val = sampleValueShort / 32768f;
                    float absVal = val < 0 ? -val : val;
                    if (absVal > maxAmplitude) maxAmplitude = absVal;
                }
            }
            else
            {
                for (int s = currSampleIdx; s < endSampleIdx - 2; s += 2 * samplesStep)
                {
                    int byteIdx1 = s * 2;
                    int byteIdx2 = (s + 1) * 2;

                    short sample1Short = (short)(data[byteIdx1] | (data[byteIdx1 + 1] << 8));
                    short sample2Short = (short)(data[byteIdx2] | (data[byteIdx2 + 1] << 8));

                    float val1 = sample1Short / 32768f;
                    float val2 = sample2Short / 32768f;
                    
                    float abs1 = val1 < 0 ? -val1 : val1;
                    float abs2 = val2 < 0 ? -val2 : val2;
                    
                    float sampleValue = (abs1 + abs2) * .5f;

                    if (sampleValue > maxAmplitude) maxAmplitude = sampleValue;
                }
            }

            amplitudes.Add(maxAmplitude);
        }

        float maxAmplitudeGlob = amplitudes.Max();
        float amplitudeMultiplier = 1.0f / maxAmplitudeGlob;
        
        for (int idx = 0; idx < amplitudes.Count; idx++)
        {
            drawMethod(image, width, height, lineWidth, idx * stepWidth, amplitudes[idx] * amplitudeMultiplier);
        }

        image.GenerateMipmaps();
        return image;
    }

	public delegate void DrawWaveformAction(Image image, int width, int height, int lineWidth, int x, double sample);
    
	public static void DrawWaveformLineThumbnail(Image image, int width, int height, int lineWidth, int x, double sample)
    { 
        
        float offset = x / (float)width;
        int heightHalf = height / 2;
        int sampleHeight = (int)(sample * height);

        Vector2I pos = new Vector2I(x, (int)(heightHalf - sampleHeight / 2.0f));
        Vector2I size = new Vector2I(lineWidth, sampleHeight);

        image.FillRect(new Rect2I(pos, size), waveformGradient.Sample(offset));
    }
	
	public static void DrawWaveformLineTimeline(Image image, int width, int height, int lineWidth, int x, double sample)
    {
        int heightHalf = height / 2;
        int sampleHeight = (int)(sample * height);

        Vector2I pos = new Vector2I(x, (int)(heightHalf - sampleHeight / 2.0f));
        Vector2I size = new Vector2I(lineWidth, sampleHeight);

        Color color = new Color(Colors.Black, .6f);

        image.FillRect(new Rect2I(pos, size), color);
    }

}

