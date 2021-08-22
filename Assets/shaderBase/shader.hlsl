Shader "Custom/baseShader"
{
	Properties
	{
		_minDistance("Distance", Float) = 0.01
		_scale("Scale", Float) = 2
		_iterations("Iterations", int) = 10
	}

		SubShader
		{
			Tags
			{
				"Queue" = "Transparent" "Render" = "Transparent" "IgnoreProjector" = "True"
			}
			Cull Off
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			Pass
			{
				CGPROGRAM
				#pragma target 3.0
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float3 worldPos : TEXCOORD0;
					float3 local : TEXCOORD1;
					float3 camPos : TEXCOORD2;
					float3 normal : TEXCOORD3;
				};

				v2f vert(appdata v)
				{
					v2f o;

					o.worldPos = mul(unity_ObjectToWorld, v.vertex);
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.local = v.vertex;
					o.camPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
					o.normal = v.normal;
					return o;
				}

				float _minDistance;
				float _scale;
				int _iterations;

				#define NUM_STEPS 100

				float4 BlendUnder(float4 color, float4 newColor)
				{
					color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
					color.a += (1.0 - color.a) * newColor.a;
					return color;
				}

				struct Hit
				{
					bool hit;
					int steps;
					float distance;
					
					float3 pos;
				};

				//disntance function
				float getDistance2(float3 pos)
				{
					return max(length(pos - float3(0.5f, 0.5f, 0.5f)) - 0.3, 0);
				}
				float getDistance(float3 z)
				{
					float3 a1 = float3(1, 1, 1);
					float3 a2 = float3(-1, -1, 1);
					float3 a3 = float3(1, -1, -1);
					float3 a4 = float3(-1, 1, -1);
					float3 c;
					int n = 0;
					float dist, d;
					while (n < _iterations) {
						c = a1; dist = length(z - a1);
						d = length(z - a2); if (d < dist) { c = a2; dist = d; }
						d = length(z - a3); if (d < dist) { c = a3; dist = d; }
						d = length(z - a4); if (d < dist) { c = a4; dist = d; }
						z = _scale * z - c * (_scale - 1.0);
						n++;
					}

					return length(z) * pow(_scale, float(-n));
				}
				bool inBounds(float3 currPos)
				{
					float tol = 0.01f;

					if (currPos.x < 0.0f - tol || currPos.x >= 1.0f + tol
						|| currPos.y < 0.0f - tol || currPos.y > 1.0f + tol
						|| currPos.z < 0.0f - tol || currPos.z > 1.0f + tol) // TODO: avoid branch?
						return false;
					return true;
				}
				
				Hit traverse(float3 start, float3 direction)
				{
					Hit hit;

					float3 currentPos = start;
					int steps = 0;
					float totalDistance = 0;
					for (uint iStep = 0; iStep < NUM_STEPS; iStep++)
					{
						float distance = getDistance(currentPos);
						currentPos += direction * distance;
						steps++;
						totalDistance += distance;
						if (distance < _minDistance)
						{
							hit.hit = true;
							hit.pos = currentPos;
							hit.steps = steps;
							hit.distance = totalDistance;
							return hit;
						}

						if (!inBounds(currentPos))
							break;
					}
					
					hit.hit = false;
					hit.pos = currentPos;
					return hit;
				}

				float3 computeNormal(float3 position, float3 right, float3 up, float3 forward)
				{
					//return float3(0, 0, 0);
					return normalize(float3(getDistance(position + right) - getDistance(position - right),
						getDistance(position + up) - getDistance(position - forward),
						getDistance(position + forward) - getDistance(position - forward)));
				}
				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = float4(0, 0, 0, 0.0);// float4(i.local.x, i.local.x, i.local.x, 0.2f);

					const float3 direction = -normalize(ObjSpaceViewDir(float4(i.local, 0.0f)));
					float3 start = i.local + float3(0.5f, 0.5f, 0.5f);
					if (inBounds(i.camPos + float3(0.5f, 0.5f, 0.5f)))
						start = i.camPos + float3(0.5f, 0.5f, 0.5f);
					const Hit hit = traverse(start, direction);
					if(hit.hit)
					{
						float3 normal = computeNormal(hit.pos, float3(1, 0, 0), float3(0, 1, 0), float3(0, 0, 1));
						col = float4(abs(normal),1);// float4((float)0.4 / hit.distance, 0, 0, 1);
					}

					return col;
				}
				ENDCG
			}
		}
	FallBack "Diffuse"
}
