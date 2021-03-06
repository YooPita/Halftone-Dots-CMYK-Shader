﻿Shader "Hidden/Halftone-Dots-CMYK-Shader-ScreenShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _DotSize("Dot Size", Range(1,5)) = 3
    }
        SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            // note: no SV_POSITION in this struct
            struct v2f {
                float2 uv : TEXCOORD0;
            };

            v2f vert(
                float4 vertex : POSITION, // vertex position input
                float2 uv : TEXCOORD0, // texture coordinate input
                out float4 outpos : SV_POSITION // clip space position output
                )
            {
                v2f o;
                o.uv = uv;
                outpos = UnityObjectToClipPos(vertex);
                return o;
            }

            sampler2D _MainTex;
            float _DotSize;

            float2 rotateUVmatrinx(float2 uv, float2 pivot, float rotation)
            {
                float2x2 rotation_matrix = float2x2(float2(sin(rotation), -cos(rotation)),
                    float2(cos(rotation), sin(rotation))
                    );
                uv -= pivot;
                uv = mul(uv, rotation_matrix);
                uv += pivot;
                return uv;
            }

            float circle(in float2 _st, in float _radius) {
                float dist = length(_st - .5) / _radius;
                float pwidth = length(float2(ddx(dist), ddy(dist)));
                float alpha = smoothstep(0.5, 0.5 - pwidth * 1.5, dist);
                return alpha;
            }

            float4 dots(in float2 uv, float ang) {
                float2 x = float2(_ScreenParams.x, _ScreenParams.y) / _DotSize;
                float2 _t = floor(uv * x) / x + _DotSize / float2(_ScreenParams.x, _ScreenParams.y) / 2;
                uv = rotateUVmatrinx(uv * x, float2(0,0), ang);
                uv = frac(uv);
                return float4(uv.x, uv.y, _t.x, _t.y);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 c = 1;
                float4 color = dots(i.uv, .25);//yellow
                float dotsize = dot(tex2D(_MainTex, color.zw), float3(0, 0, 1));
                c.rgb = c - circle(color , 2 - saturate(dotsize) * 2) * float3(0, 0, 1);

                color = dots(i.uv, .392);//cyan
                dotsize = dot(tex2D(_MainTex, color.zw), float3(1, 0, 0));
                c.rgb = c - circle(color, 2 - saturate(dotsize) * 2) * float3(1, 0, 0);

                color = dots(i.uv, 1.177);//magenta
                dotsize = dot(tex2D(_MainTex, color.zw), float3(0, 1, 0));
                c.rgb = c - circle(color, 2 - saturate(dotsize) * 2) * float3(0, 1, 0);

                color = dots(i.uv, 0.785);//black
                float3 dc = tex2D(_MainTex, color.zw);
                dotsize = (dc.r + dc.g + dc.b) / 3;
                c.rgb = c - circle(color, 1 - saturate(dotsize)) * float3(1, 1, 1);

                return c;
            }
            ENDCG
        }
    }
}