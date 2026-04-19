using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;

[GlobalClass]
public partial class MediaHelper : GodotObject
{
    public static Gradient waveformGradient = default;

    public static Gradient GetWaveformGradient() { return waveformGradient; }
    public static void SetWaveformGradient(Gradient newVal) { waveformGradient = newVal; }

    private static Dictionary<long, byte[]> audioDataIDs = new();

    public static void PushAudioData(long dataID, byte[] data)
    {
        audioDataIDs.TryAdd(dataID, data);
    }
    
    public static void FreeAudioData(long dataID)
    {
        audioDataIDs.Remove(dataID);
    }

    public static Image GenerateWaveformImage(long dataID, double secondFrom, double secondTo, Image.Format imageFormat, int width, int height, int spaceWidth, int lineWidth, int drawMethodIDX = 0, Color bgColor = default)
    {
        if (!audioDataIDs.ContainsKey(dataID)) return null;
        
        DrawWaveformAction drawMethod = drawMethodIDX == 0 ? DrawWaveformLineThumbnail : DrawWaveformLineTimeline;

        Image image = Image.CreateEmpty(width, height, false, imageFormat);
        image.Fill(bgColor);

        byte[] rawData = audioDataIDs[dataID];
        
        int channels = 2;
        int sampleRate = 48000;
        int bytesPerSample = 4; // Float32
        int bytesPerFrame = bytesPerSample * channels;

        ReadOnlySpan<float> floatData = MemoryMarshal.Cast<byte, float>(rawData);

        double length = rawData.Length / (double)(bytesPerFrame * sampleRate);
        secondTo = Math.Min(secondTo, length);
        double duration = secondTo - secondFrom;
        
        int startSample = (int)(secondFrom * sampleRate);
        int totalSamplesToProcess = (int)(duration * sampleRate);
        
        int samplesPerPixel = totalSamplesToProcess / width;
        if (samplesPerPixel < 1) samplesPerPixel = 1;

        int stepWidth = spaceWidth + lineWidth;
        int linesCount = width / stepWidth;

        int samplesStep = 1;
        if (samplesPerPixel > 100_000) samplesStep = 10_000;
        else if (samplesPerPixel > 10_000) samplesStep = 1_000;
        else if (samplesPerPixel > 1000) samplesStep = 100;
        else if (samplesPerPixel > 100) samplesStep = 10;

        List<float> amplitudes = new List<float>(linesCount);

        for (int x = 0; x < linesCount; x++)
        {
            int pixelX = x * stepWidth;
            
            int currSampleIdx = (startSample + (pixelX * samplesPerPixel)) * channels;
            int endSampleIdx = currSampleIdx + (samplesPerPixel * channels);

            float maxAmplitude = 0.0f;

            if (currSampleIdx >= floatData.Length)
            {
                amplitudes.Add(0.0f);
                continue;
            }
            endSampleIdx = Math.Min(endSampleIdx, floatData.Length);

            for (int s = currSampleIdx; s < endSampleIdx - 1; s += 2 * samplesStep)
            {
                float abs1 = Math.Abs(floatData[s]);     // Left
                float abs2 = Math.Abs(floatData[s + 1]); // Right
                
                float sampleValue = (abs1 + abs2) * 0.5f;
                if (sampleValue > maxAmplitude) maxAmplitude = sampleValue;
            }

            amplitudes.Add(maxAmplitude);
        }

        float maxAmplitudeGlob = amplitudes.Count > 0 ? amplitudes.Max() : 0;
        float amplitudeMultiplier = maxAmplitudeGlob > .0f ? 1.0f / maxAmplitudeGlob : 1.0f;

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
        float offset = x / (float)image.GetWidth();
        int heightHalf = height / 2;
        int sampleHeight = (int)(sample * height);

        Vector2I pos = new Vector2I(x, (int)(heightHalf - sampleHeight / 2.0f));
        Vector2I size = new Vector2I(lineWidth, Math.Max(1, sampleHeight));

        image.FillRect(new Rect2I(pos, size), waveformGradient.Sample(offset));
    }
    
    public static void DrawWaveformLineTimeline(Image image, int width, int height, int lineWidth, int x, double sample)
    {
        int heightHalf = height / 2;
        int sampleHeight = (int)(sample * height);

        Vector2I pos = new Vector2I(x, (int)(heightHalf - sampleHeight / 2.0f));
        Vector2I size = new Vector2I(lineWidth, Math.Max(1, sampleHeight));

        Color color = new Color(Colors.Black, 0.6f);
        image.FillRect(new Rect2I(pos, size), color);
    }
}