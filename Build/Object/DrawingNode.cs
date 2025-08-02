using Godot;
using System;
using System.Linq;

// DrawingNode Class
[GlobalClass]
public partial class DrawingNode : Node2D
{
    [Export] public DrawingRes DrawingRes { get; set; }

    public override void _Ready()
    {
        if (DrawingRes != null)
        {
            DrawingRes.PointsChanged += QueueRedraw;
            DrawingRes.EntitiesChanged += QueueRedraw;
        }
    }

    public override void _Draw()
    {
        if (DrawingRes == null)
            return;

        var points = DrawingRes.Points;
        var pointsSize = points.Count;

        if (pointsSize == 0)
            return;

        var drawnEntities = DrawingRes.DrawnEntities;

        var lineColor = DrawingRes.ColorLine;
        var fillColor = DrawingRes.ColorFill;
        var colorRange = DrawingRes.ColorRange;

        var width = DrawingRes.MainWidth;
        var antialised = DrawingRes.Antialised;

        var wbc = DrawingRes.WidthBeginCurve;
        var wec = DrawingRes.WidthEndCurve;
        var wbd = DrawingRes.WidthBeginDist;
        var wed = DrawingRes.WidthEndDist;

        // -------------------- Draw Fill --------------------
        if (DrawingRes.DrawFill)
        {
            DrawPolygon(points.ToArray(), new Color[]{fillColor});
        }

        // -------------------- Draw Line --------------------
        float distPassed = 0;
        float distMax = 0;

        Vector2? latestPoint = null;

        foreach (Vector2 point in points)
        {
            if (latestPoint.HasValue)
            {
                distMax += point.DistanceTo(latestPoint.Value);
            }
            latestPoint = point;
        }

        float distLeft = 0;

        if (!DrawingRes.DrawLine)
            return;

        for (int time = 0; time < pointsSize; time++)
        {
            if (time < pointsSize - 1)
            {
                var p1 = points[time];
                var p2 = points[time + 1];
                var currWidth = width;

                var ratio = (float)time / pointsSize;

                var aToBDist = p1.DistanceTo(p2);

                switch (DrawingRes.WidthCurveRangeType)
                {
                    case DrawingRes.RangeTypes.Dist:
                        distPassed += aToBDist;
                        if (ratio < 0.5f)
                        {
                            currWidth *= SampleCurve(wbc, distPassed / wbd);
                        }
                        else
                        {
                            currWidth *= SampleCurve(wec, (distMax - distPassed) / wed);
                        }
                        break;
                    case DrawingRes.RangeTypes.Ratio:
                        var ratioDoubled = ratio * 2.0f;
                        if (ratio < 0.5f)
                        {
                            currWidth *= SampleCurve(wbc, ratioDoubled);
                        }
                        else
                        {
                            currWidth *= SampleCurve(wec, 1.0f - (ratioDoubled - 1.0f));
                        }
                        break;
                }

                if (colorRange != null)
                {
                    lineColor = colorRange.Sample(ratio);
                }

                foreach (var drawnEntity in drawnEntities)
                {
                    var type = drawnEntity.Keys.First().AsString();
                    var info = drawnEntity.Values.First().AsGodotDictionary();
                    var dist = info["dist"].AsInt32();
                    var range = info["range"].AsGodotArray();
                    var distMode = info["dist_mode"].AsInt32();

                    int drawTimes = 1;

                    if (distMode == 1)
                    {
                        var fullTimes = aToBDist + distLeft;
                        drawTimes = Mathf.FloorToInt(fullTimes / dist);
                        var newDistLeft = Mathf.PosMod(fullTimes, dist * drawTimes);
                        if (float.IsNaN(newDistLeft))
                        {
                            newDistLeft = aToBDist;
                        }
                        if (drawTimes > 0)
                        {
                            distLeft = newDistLeft;
                        }
                        else
                        {
                            distLeft += newDistLeft;
                        }
                    }
                    else
                    {
                        if (time % dist != 0)
                            continue;
                    }

                    if (ratio < range[0].AsSingle() || ratio > range[1].AsSingle())
                        continue;

                    var offset = info["offset"].AsVector2();
                    var drawColor = info["custom_color"].AsColor();
                    var drawWidth = info["custom_width"].AsSingle();
                    var drawAntialised = info["custom_antialiased"].AsBool();

					drawColor = lineColor;
					drawWidth = currWidth;
					drawAntialised = antialised;

                    p1 += offset;
                    p2 += offset;

                    for (int drawTime = 0; drawTime < drawTimes; drawTime++)
                    {
                        var timeDrawOffset = drawTime * dist / aToBDist;
                        var point = p1 + (p2 - p1) * timeDrawOffset;

                        switch (type)
                        {
                            case "line":
                                DrawLine(p1, p2, drawColor, drawWidth, drawAntialised);
                                break;
                            case "dashed_line":
                                DrawDashedLine(p1, p2, drawColor, drawWidth, info["dash"].AsSingle(), true, drawAntialised);
                                break;
                            case "rect":
                                var sizeResult = info["rect_size"].AsVector2() * drawWidth;
                                DrawRect(new Rect2(point - sizeResult / 2.0f, sizeResult), drawColor, info["filled"].AsBool(), info["width_scale"].AsSingle(), drawAntialised);
                                break;
                            case "circle":
                                DrawCircle(point, drawWidth / 2.0f, drawColor, info["filled"].AsBool(), info["width_scale"].AsSingle(), drawAntialised);
                                break;
                            case "arc":
                                DrawArc(point, drawWidth / 2.0f, info["start_angle"].AsSingle(), info["end_angle"].AsSingle(), info["points_count"].AsInt32(), drawColor, info["width_scale"].AsSingle(), drawAntialised);
                                break;
                            case "mesh":
                                DrawMesh(info["mesh"].As<Mesh>(), info["texture"].As<Texture2D>(), 
                                    new Transform2D(info["rotation"].AsSingle(), info["scale"].AsVector2() * drawWidth, info["skew"].AsSingle(), point), drawColor);
                                break;
                            case "texture":
                                DrawTexture(info["texture"].As<Texture2D>(), point, drawColor);
                                break;
                        }
                    }
                }
            }
        }

        // -------------------- Draw Caps --------------------
        var beginWidth = width * DrawingRes.CapBeginScale * SampleCurve(wbc, 0.0f);
        var endWidth = width * DrawingRes.CapEndScale * SampleCurve(wec, 0.0f);
        var frontPoint = points[0];
        var backPoint = points[points.Count - 1];

        switch (DrawingRes.CapBeginType)
        {
            case DrawingRes.CapsTypes.Round:
                DrawCircle(frontPoint, beginWidth, lineColor, true, -1.0f, true);
                break;
        }

        switch (DrawingRes.CapEndType)
        {
            case DrawingRes.CapsTypes.Round:
                DrawCircle(backPoint, endWidth, lineColor, true, -1.0f, true);
                break;
        }
    }



    private float SampleCurve(Curve curve, float offset)
    {
        if (curve != null)
            return curve.Sample(offset);
        return 1.0f;
    }
}