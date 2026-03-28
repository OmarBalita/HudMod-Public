using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;

[GlobalClass]
public partial class CustomMath : GodotObject
{
	static int[] get_divisors(int n)
	{
		List<int> divisors = new List<int>();
		
		for (int idx = 2; idx < n; idx++)
		{
			if (n % idx == 0)
			{
				divisors.Add(n / idx);
			}
		}
		
		return divisors.ToArray();
	}

	static int find_larger_divisor(int n)
	{
		return get_divisors(n).Max();
	}
}

