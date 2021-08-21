Shader "Custom/volumeSh"
{
	Properties
	{
		_minDistance("Distance", Int) = 0.01

	}

		SubShader
		{
			Tags
			{
				"Queue" = "Transparent" "Render" = "Transparent" "IgnoreProjector" = "True"
			}

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
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float3 worldPos : TEXCOORD0;
					float3 local : TEXCOORD1;
					float3 camPos : TEXCOORD2;
				};

				v2f vert(appdata v)
				{
					v2f o;

					o.worldPos = mul(unity_ObjectToWorld, v.vertex);
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.local = v.vertex;
					o.camPos = mul(unity_WorldToObject, _WorldSpaceCameraPos);
					return o;
				}

				float _minDistance;
				#define NUM_STEPS 100

				float4 BlendUnder(float4 color, float4 newColor)
				{
					color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
					color.a += (1.0 - color.a) * newColor.a;
					return color;
				}


				//disntance function
				float getDistance(float3 pos)
				{
					return max(length(pos - float3(0.5f, 0.5f, 0.5f)) - 0.15, 0);
				}

				struct Hit
				{
					bool hit;
					float3 pos;
				};
				
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

					for (uint iStep = 0; iStep < NUM_STEPS; iStep++)
					{
						float distance = getDistance(currentPos);

						currentPos += direction * distance;
						if (distance < _minDistance)
						{
							hit.hit = true;
							hit.pos = currentPos;
							return hit;
						}

						if (!inBounds(currentPos))
							break;
					}
					
					hit.hit = false;
					hit.pos = currentPos;
					return hit;
				}
				
				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = float4(0, 0, 0, 0.0);// float4(i.local.x, i.local.x, i.local.x, 0.2f);

					const float3 direction = -normalize(ObjSpaceViewDir(float4(i.local, 0.0f)));
					const float3 start = i.local + float3(0.5f, 0.5f, 0.5f);
					Hit hit = traverse(start, direction);
					if(hit.hit)
					{
						col = float4(1, 0, 0, 1);
					}
					float3 currPos = start;

					return col;
				}
				ENDCG
			}
		}
	FallBack "Diffuse"
}
