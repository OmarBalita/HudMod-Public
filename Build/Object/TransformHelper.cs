using System;
using System.Linq;
using Godot;
using Godot.Collections;


[GlobalClass]
public partial class TransformHelper : Resource
{

	public static Dictionary<Resource, Dictionary> MovePoints(Dictionary<Resource, Dictionary<int, Vector2>> points, Vector2 offset)
	{
		return LoopPoints(points, (d, i, p) => p + offset);
	}
	public static Dictionary<Resource, Dictionary> RotatePoints(Dictionary<Resource, Dictionary<int, Vector2>> points, float degrees, Callable centerFunc)
	{
		return LoopPoints(points, (d, i, p) => RotatePoint(d, p, degrees, centerFunc));
	}
	public static Dictionary<Resource, Dictionary> ScalePoints(Dictionary<Resource, Dictionary<int, Vector2>> points, float scaleTime, Callable centerFunc, bool scaleX, bool scaleY)
	{
		return LoopPoints(points, (d, i, p) => ScalePoint(d, p, scaleTime, centerFunc, scaleX, scaleY));
	}


	private static Vector2 RotatePoint(Resource drawingRes, Vector2 point, float degrees, Callable centerFunc)
	{
		float angleRad = Mathf.DegToRad(degrees);
		Vector2 offset = point - (Vector2)centerFunc.Call(drawingRes, 0, point);

		return new Vector2(
			offset.X * Mathf.Cos(angleRad) - offset.Y * Mathf.Sin(angleRad),
			offset.X * Mathf.Sin(angleRad) + offset.Y * Mathf.Cos(angleRad)
		);
	}

	private static Vector2 ScalePoint(Resource drawingRes, Vector2 point, float scaleTime, Callable centerFunc, bool scaleX, bool scaleY)
	{
		float newX = point.X;
		float newY = point.Y;

		Vector2 center = (Vector2)centerFunc.Call(drawingRes, 0, point);

		if (scaleX) newX = center.X + (point.X - center.X) * scaleTime;
		if (scaleY) newY = center.Y + (point.Y - center.Y) * scaleTime;

		return new Vector2(newX, newY);
	}


	private static Dictionary<Resource, Dictionary> LoopPoints(Dictionary<Resource, Dictionary<int, Vector2>> points, Func<Resource, int, Vector2, Vector2> function)
	{
		Dictionary<Resource, Dictionary> result = new();

		foreach (Resource drawingRes in points.Keys)
		{
			result[drawingRes] = new();
			
			Array<Vector2> drawingPoints = (Array<Vector2>)points[drawingRes].Values;
			for (int index = 0; index < drawingPoints.Count; index++)
			{
				Vector2 point = drawingPoints[index];
				Vector2 newPoint = function.Invoke(drawingRes, index, point);

				result[drawingRes].Add(index, newPoint);
			}
		}
		return result;
	}
	
}

