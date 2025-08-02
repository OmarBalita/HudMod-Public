using Godot;

[GlobalClass]
public partial class Draw : Node2D
{
    [Export] public Godot.Collections.Array<DrawingRes> DrawingsRess { get; set; } = new();
    private DrawingRes _currDrawingRes;

    [ExportGroup("Default Properties")]
    [Export] public Gradient DefaultColorRange { get; set; }
    [Export] public Curve DefaultWidthCurve { get; set; }

    private Godot.Collections.Array _drawFillPoints = new();
    private int _drawGridSize;

    public override void _Draw()
    {
        var gridSize = Vector2I.One * _drawGridSize;
        foreach (Vector2I fillPoint in _drawFillPoints)
        {
            DrawRect(new Rect2(fillPoint * gridSize, gridSize), Colors.MediumPurple);
        }
    }

    public DrawingRes StartNewDrawing(Vector2 startPoint)
    {
        var drawingRes = new DrawingRes();
        SetupDrawingRes(drawingRes);
        drawingRes.AddPoint(startPoint);
        
        DrawingsRess.Add(drawingRes);
        _currDrawingRes = drawingRes;
        
        UpdateDrawings();
        
        return drawingRes;
    }

    public void CreateNewDrawing(Godot.Collections.Array<Vector2> points)
    {
        var drawingRes = new DrawingRes();
        SetupDrawingRes(drawingRes);
        drawingRes.Points = points;
        
        DrawingsRess.Add(drawingRes);
        
        UpdateDrawings();
        
    }

    private void SetupDrawingRes(DrawingRes drawingRes)
    {
        Gradient colorRangeDuplicated = null;
        Curve curveDuplicated = null;
        
        if (DefaultColorRange != null)
            colorRangeDuplicated = (Gradient)DefaultColorRange.Duplicate(true);
        if (DefaultWidthCurve != null)
            curveDuplicated = (Curve)DefaultWidthCurve.Duplicate(true);
        
        drawingRes.ColorRange = colorRangeDuplicated;
        drawingRes.WidthBeginCurve = curveDuplicated;
        drawingRes.WidthEndCurve = curveDuplicated;
        drawingRes.EntityLine();
        
        drawingRes.Sliced += CreateNewDrawing;
    }

    public void AddPointToCurrentDrawing(Vector2 newPoint)
    {
        _currDrawingRes?.AddPoint(newPoint);
    }

    public void EraseDrawingNodes(Vector2 pos, float eraserScale)
    {
        foreach (var drawingRes in DrawingsRess)
        {
            drawingRes.Erase(pos, eraserScale);
        }
    }

    private Godot.Collections.Array _drawingsSubdvPoints = new();

    public void FillDrawingNodes(Vector2I pos, int gridSize = 5)
    {
        BakeDrawingSubdvPoints(gridSize);
        
        var fillPoints = GetFillFromPosBfs(gridSize, GetWindow().Size, pos);
        
        _drawFillPoints = fillPoints;
        _drawGridSize = gridSize;
        QueueRedraw();
    }

    private void BakeDrawingSubdvPoints(int gridSize)
    {
        _drawingsSubdvPoints = new Godot.Collections.Array();
        
        foreach (var drawingRes in DrawingsRess)
        {
            var points = drawingRes.Points;
            var subdivPoints = new Godot.Collections.Array<Vector2>();
            
            for (int index = 0; index < points.Count; index++)
            {
                var p1 = points[index];
                subdivPoints.Add(p1);
                
                if (index < points.Count - 1)
                {
                    var p2 = points[index + 1];
                    var aToDistBist = p1.DistanceTo(p2);
                    
                    if (aToDistBist >= gridSize)
                    {
                        var offsetTimes = Mathf.CeilToInt(aToDistBist / gridSize);
                        for (int offsetTime = 1; offsetTime < offsetTimes; offsetTime++)
                        {
                            var offset = offsetTime * gridSize / aToDistBist;
                            var point = p1 + (p2 - p1) * offset;
                            subdivPoints.Add(point);
                        }
                    }
                }
            }
            
            _drawingsSubdvPoints.Add(subdivPoints);
        }
    }

    // Made By Claude-AI، بتصرف
    private static readonly Vector2I[] DIRECTIONS = {
        new Vector2I(0, -1),  // أعلى
        new Vector2I(0, 1),   // أسفل
        new Vector2I(-1, 0),  // يسار
        new Vector2I(1, 0)    // يمين
    };

    private Godot.Collections.Array GetFillFromPosBfs(int gridSize, Vector2I gridRectSize, Vector2I startPos, 
        Godot.Collections.Array filledPositions = null, int maxIterations = 100000)
    {
        gridRectSize /= gridSize;
        startPos /= gridSize;
        
        // تحديد حدود الشبكة
        var gridBounds = new Rect2I(-gridRectSize / 2, gridRectSize);
        
        // مصفوفة لتتبع الخلايا المزارة
        var visited = new Godot.Collections.Dictionary();
        
        // قائمة انتظار للخلايا المراد فحصها (FIFO للـ BFS)
        var queue = new Godot.Collections.Array { startPos };
        var result = new Godot.Collections.Array();
        
        while (queue.Count > 0 && result.Count < maxIterations)
        {
            // أخذ أول عنصر من القائمة (FIFO)
            var currPos = (Vector2I)queue[0];
            queue.RemoveAt(0);
            
            // تحقق من صحة الموقع
            if (!gridBounds.HasPoint(currPos))
                continue;
            
            // تحقق من أن الخلية لم تُزار من قبل
            var posKey = currPos.X + "," + currPos.Y;
            if (visited.ContainsKey(posKey))
                continue;
            
            if (IsRectHasAnyPoint(new Rect2(currPos * gridSize, new Vector2(gridSize, gridSize))))
                continue;
            
            // إضافة الموقع للنتيجة وتسجيله كمُزار
            visited[posKey] = true;
            result.Add(currPos);
            
            // إضافة الخلايا المجاورة لنهاية القائمة (الاتجاهات الأربع)
            foreach (var direction in DIRECTIONS)
            {
                var nextPos = currPos + direction;
                queue.Add(nextPos);  // يُضاف في النهاية
            }
        }
        
        return result;
    }

    private bool IsRectHasAnyPoint(Rect2 rect)
    {
        foreach (Godot.Collections.Array<Vector2> subdivPoints in _drawingsSubdvPoints)
        {
            foreach (var point in subdivPoints)
            {
                if (rect.HasPoint(point))
                    return true;
            }
        }
        return false;
    }

    public void UpdateDrawings()
    {
        foreach (Node child in GetChildren())
        {
            if (child is DrawingNode drawingNode)
            {
                var drawingRes = drawingNode.DrawingRes;
                if (drawingRes.Points.Count == 0)
                {
                    DrawingsRess.Remove(drawingRes);
                }
                child.QueueFree();
            }
        }
        
        foreach (DrawingRes drawingRes in DrawingsRess)
        {
            var drawingNode = new DrawingNode();
            drawingNode.DrawingRes = drawingRes;
            AddChild(drawingNode);
        }
    }
}