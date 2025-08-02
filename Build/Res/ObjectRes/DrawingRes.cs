using Godot;
using Microsoft.VisualBasic;
using System;
using System.Linq;

[GlobalClass]
public partial class DrawingRes : Node
{
    [Signal] public delegate void PointsChangedEventHandler();
    [Signal] public delegate void EntitiesChangedEventHandler();
    [Signal] public delegate void SlicedEventHandler(Godot.Collections.Array<Vector2> rightSlicePoints);

    public enum RangeTypes
    {
        Dist = 0,
        Ratio = 1
    }

    public enum CapsTypes
    {
        None = 0,
        Round = 2
    }

    public enum DistMode
    {
        PointsDist = 0,
        ConstDist = 1
    }

    [Export] public Godot.Collections.Array<Vector2> Points { get; set; } = new();
    [Export] public Godot.Collections.Array<Godot.Collections.Dictionary> DrawnEntities { get; set; } = new();
    [Export] public bool DrawLine { get; set; } = true;
    [Export] public bool DrawFill { get; set; } = false;

    [ExportGroup("Default Properties")]
    [Export] public bool Antialised { get; set; } = true;

    [ExportSubgroup("Color")]
    [Export] public Color ColorLine { get; set; } = Colors.White;
    [Export] public Color ColorFill { get; set; } = Colors.Gray;
    [Export] public Gradient ColorRange { get; set; }

    [ExportSubgroup("Width")]
    [Export(PropertyHint.Range, "0.01,1000.0")] public float MainWidth { get; set; } = 5.0f;
    [Export] public RangeTypes WidthCurveRangeType { get; set; } = RangeTypes.Dist;
    [Export] public Curve WidthBeginCurve { get; set; }
    [Export] public Curve WidthEndCurve { get; set; }
    [Export] public float WidthBeginDist { get; set; } = 60.0f;
    [Export] public float WidthEndDist { get; set; } = 60.0f;

    [ExportSubgroup("Capping")]
    [Export] public CapsTypes CapBeginType { get; set; } = CapsTypes.None;
    [Export] public CapsTypes CapEndType { get; set; } = CapsTypes.None;
    [Export] public float CapBeginScale 
    { 
        get => _capBeginScale / (int)CapBeginType; 
        set => _capBeginScale = value; 
    }
    [Export] public float CapEndScale 
    { 
        get => _capEndScale / (int)CapEndType; 
        set => _capEndScale = value; 
    }

    private float _capBeginScale = 1.0f;
    private float _capEndScale = 1.0f;

    public Godot.Collections.Array<Vector2> GetPoints()
    {
        return Points;
    }

    public void SetPoints(Godot.Collections.Array<Vector2> points)
    {
        Points = points;
        EmitSignal(SignalName.PointsChanged);
    }

    public void AddPoint(Vector2 point)
    {
        Points.Add(point);
        EmitSignal(SignalName.PointsChanged);
    }

    public void EntityLine(Vector2 offset = default, int dist = 1, Godot.Collections.Array range = null, 
        Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        Entity(new Godot.Collections.Dictionary { 
            { "line", GetBaseEntityProperties(offset, dist, 0, range, customColor, customWidth, customAntialiased) } 
        });
    }

    public void EntityDashedLine(float dash = 2.0f, Vector2 offset = default, int dist = 1, 
        Godot.Collections.Array range = null, Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        var baseProps = GetBaseEntityProperties(offset, dist, 0, range, customColor, customWidth, customAntialiased);
        baseProps["dash"] = dash;
        Entity(new Godot.Collections.Dictionary { { "dashed_line", baseProps } });
    }

    public void EntityVDashedLine(float dashSize = 2.0f, Vector2 offset = default, int dist = 1, 
        Godot.Collections.Array range = null, Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        var baseProps = GetBaseEntityProperties(offset, dist, 0, range, customColor, customWidth, customAntialiased);
        baseProps["dash_size"] = dashSize;
        Entity(new Godot.Collections.Dictionary { { "v_dashed_line", baseProps } });
    }

    public void EntityRect(Vector2 rectSize = default, bool filled = false, float widthScale = 1.0f, 
        Vector2 offset = default, int dist = 1, DistMode distMode = DistMode.PointsDist, 
        Godot.Collections.Array range = null, Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        if (rectSize == default) rectSize = Vector2.One;
        var baseProps = GetBaseEntityProperties(offset, dist, (int)distMode, range, customColor, customWidth, customAntialiased);
        baseProps["rect_size"] = rectSize;
        baseProps["filled"] = filled;
        baseProps["width_scale"] = widthScale;
        Entity(new Godot.Collections.Dictionary { { "rect", baseProps } });
    }

    public void EntityCircle(bool filled = false, float widthScale = -1.0f, Vector2 offset = default, 
        int dist = 1, DistMode distMode = DistMode.PointsDist, Godot.Collections.Array range = null, 
        Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        var baseProps = GetBaseEntityProperties(offset, dist, (int)distMode, range, customColor, customWidth, customAntialiased);
        baseProps["filled"] = filled;
        baseProps["width_scale"] = widthScale;
        Entity(new Godot.Collections.Dictionary { { "circle", baseProps } });
    }

    public void EntityArc(float startAngle = 0, float endAngle = Mathf.Tau, float pointsCount = 8, 
        float widthScale = -1.0f, Vector2 offset = default, int dist = 1, DistMode distMode = DistMode.PointsDist, 
        Godot.Collections.Array range = null, Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        var baseProps = GetBaseEntityProperties(offset, dist, (int)distMode, range, customColor, customWidth, customAntialiased);
        baseProps["start_angle"] = startAngle;
        baseProps["end_angle"] = endAngle;
        baseProps["points_count"] = pointsCount;
        baseProps["width_scale"] = widthScale;
        Entity(new Godot.Collections.Dictionary { { "arc", baseProps } });
    }

    public void EntityMesh(Mesh mesh = null, Texture2D texture = null, float rotation = 0.0f, 
        Vector2 scale = default, float skew = 0.0f, Vector2 offset = default, int dist = 1, 
        DistMode distMode = DistMode.PointsDist, Godot.Collections.Array range = null, 
        Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        if (scale == default) scale = Vector2.One;
        var baseProps = GetBaseEntityProperties(offset, dist, (int)distMode, range, customColor, customWidth, customAntialiased);
        baseProps["mesh"] = mesh;
        baseProps["texture"] = texture;
        baseProps["rotation"] = rotation;
        baseProps["scale"] = scale;
        baseProps["skew"] = skew;
        Entity(new Godot.Collections.Dictionary { { "mesh", baseProps } });
    }

    public void EntityTexture(Texture2D texture = null, Vector2 offset = default, int dist = 1, 
        DistMode distMode = DistMode.PointsDist, Godot.Collections.Array range = null, 
        Color customColor = new Color(), float customWidth = 1f, bool customAntialiased = true)
    {
        var baseProps = GetBaseEntityProperties(offset, dist, (int)distMode, range, customColor, customWidth, customAntialiased);
        baseProps["texture"] = texture;
        Entity(new Godot.Collections.Dictionary { { "texture", baseProps } });
    }

    public void Entity(Godot.Collections.Dictionary entity)
    {
        DrawnEntities.Add(entity);
    }
	
	private Godot.Collections.Dictionary GetBaseEntityProperties(Vector2 offset, int dist, int distMode,
		Godot.Collections.Array range, Color customColor, float customWidth, bool customAntialiased)
	{
		if (range == null)
			range = new Godot.Collections.Array { 0, 1 };

		return new Godot.Collections.Dictionary
		{
			{ "offset", offset },
			{ "dist", dist },
			{ "range", range },
			{ "dist_mode", distMode },
			{ "custom_color", customColor },
			{ "custom_width", customWidth },
			{ "custom_antialiased", customAntialiased }
		};
	}


    public void ClearEntities()
    {
        DrawnEntities.Clear();
        EmitSignal(SignalName.EntitiesChanged);
    }

    // Made by AI
    public void Erase(Vector2 pos, float eraserScale)
    {
        var pointsToRemove = new Godot.Collections.Array<int>();

        // جمع فهارس النقاط المراد حذفها
        for (int index = 0; index < Points.Count; index++)
        {
            var point = Points[index];
            if (point.DistanceTo(pos) <= eraserScale)
            {
                pointsToRemove.Add(index);
            }
        }

        if (pointsToRemove.Count == 0)
            return;

        // إذا كانت النقاط المحذوفة متتالية، قسم الخط
        if (IsContinuousSegment(pointsToRemove))
        {
            var firstRemoved = pointsToRemove[0];
            var lastRemoved = pointsToRemove[pointsToRemove.Count - 1];

            // الجزء الأيمن (بعد المنطقة المحذوفة)
            if (lastRemoved + 1 < Points.Count)
            {
                var rightSlice = new Godot.Collections.Array<Vector2>();
                for (int i = lastRemoved + 1; i < Points.Count; i++)
                {
                    rightSlice.Add(Points[i]);
                }
                if (rightSlice.Count > 1)
                {
                    EmitSignal(SignalName.Sliced, rightSlice);
                }
            }

            // قطع النقاط من المنطقة المحذوفة
            if (firstRemoved > 0)
            {
                var newPoints = new Godot.Collections.Array<Vector2>();
                for (int i = 0; i < firstRemoved; i++)
                {
                    newPoints.Add(Points[i]);
                }
                Points = newPoints;
            }
            else
            {
                Points.Clear();
            }
        }
        else
        {
            // إذا كانت النقاط متفرقة، احذفها من الخلف للأمام
            var reversedIndices = pointsToRemove.ToArray().Reverse().ToArray();
            foreach (int index in reversedIndices)
            {
                Points.RemoveAt(index);
            }
        }

        EmitSignal(SignalName.PointsChanged);
    }

    // Made by AI
    // دالة مساعدة للتحقق من تتالي النقاط المحذوفة
    private bool IsContinuousSegment(Godot.Collections.Array<int> indices)
    {
        if (indices.Count <= 1)
            return true;

        for (int i = 1; i < indices.Count; i++)
        {
            if (indices[i] != indices[i - 1] + 1)
                return false;
        }

        return true;
    }
}