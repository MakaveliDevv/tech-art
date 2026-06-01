Shader "Custom/HologramShader2"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (0, 1, 1, 1)
        
        _LineColor("Line Color", Color) = (0, 1, 1, 1)

        _RimColor("Rim Color", Color) = (0, 1, 1, 1)
        _RimPower("Rim Power", Range(0.5, 10)) = 4

        _ScanlineSpeed("Scanline Speed", Float) = 2
        _ScanlineDensity("Scanline Density", Float) = 50

        _BaseAlpha("Base Alpha", Range(0, 1)) = 0.05
        _RimAlpha("Rim Alpha", Range(0, 1)) = 0.75
        _ScanlineAlpha("Scanline Alpha", Range(0, 1)) = 0.25
        _PulseStrength("Pulse Strength", Range(0, 1)) = 0.1

        // Numbers
        _NumberColor("Number Color", Color) = (0, 1, 1, 1)
        _NumberAlpha("Number Alpha", Range(0, 1)) = 0.8
        _NumberColumns("Number Columns", Float) = 12
        _NumberRows("Number Rows", Float) = 20
        _NumberSpeed("Number Speed", Float) = 0.5
        _NumberThickness("Number Thickness", Range(0.02, 0.2)) = 0.08
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "LightMode" = "UniversalForward" }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back
        ZWrite Off

        Pass
        {
            Name "HologramBasePass"

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
               float4 positionHCS : SV_POSITION;
               float3 worldPos : TEXCOORD0;
               float3 worldNormal : TEXCOORD1;
               float3 viewDir : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)

                half4 _BaseColor;
                half4 _LineColor;

                half4 _RimColor;
                float _RimPower;
                
                float _ScanlineSpeed;
                float _ScanlineDensity;
                
                float _BaseAlpha;
                float _RimAlpha;
                float _ScanlineAlpha;
                float _PulseStrength;

            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.worldNormal = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.viewDir = normalize(GetWorldSpaceViewDir(OUT.worldPos));

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float rimGlow = 1 - saturate(dot(IN.viewDir, IN.worldNormal));
                rimGlow = pow(rimGlow, _RimPower);

                float scanLines = sin(IN.worldPos.y * _ScanlineDensity + _Time.y * _ScanlineSpeed);
                scanLines = scanLines * 0.5 + 0.5;

                float pulse = sin(_Time.y * 2) * 0.5 + 0.5;

                float hologramIntensity = rimGlow + pulse * _PulseStrength;
                float lineIntensity = scanLines * 0.3;

                half3 lineColor = _LineColor.rgb * lineIntensity;
                half3 finalColor = _BaseColor.rgb * hologramIntensity + _RimColor.rgb * rimGlow + lineColor;

                float finalAlpha = _BaseAlpha + rimGlow * _RimAlpha + scanLines * _ScanlineAlpha;

                finalAlpha = saturate(finalAlpha);

                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }

        Pass
        {
            Name "FallingNumbersPass"

            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }

            Blend SrcAlpha One
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)

                half4 _NumberColor;
                float _NumberAlpha;
                float _NumberColumns;
                float _NumberRows;
                float _NumberSpeed;
                float _NumberThickness;

            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;

                return OUT;
            }

            float random(float2 value)
            {
                return frac(sin(dot(value, float2(12.9898, 78.233))) * 43758.5453);
            }

            float box(float2 uv, float2 center, float2 size)
            {
                float2 distanceFromCenter = abs(uv - center);
                float2 halfSize = size * 0.5;

                float insideX = step(distanceFromCenter.x, halfSize.x);
                float insideY = step(distanceFromCenter.y, halfSize.y);

                return insideX * insideY;
            }

            float drawDigit(float2 uv, int digit, float thickness)
            {
                float segmentA = box(uv, float2(0.5, 0.88), float2(0.55, thickness));
                float segmentB = box(uv, float2(0.78, 0.66), float2(thickness, 0.35));
                float segmentC = box(uv, float2(0.78, 0.28), float2(thickness, 0.35));
                float segmentD = box(uv, float2(0.5, 0.10), float2(0.55, thickness));
                float segmentE = box(uv, float2(0.22, 0.28), float2(thickness, 0.35));
                float segmentF = box(uv, float2(0.22, 0.66), float2(thickness, 0.35));
                float segmentG = box(uv, float2(0.5, 0.49), float2(0.55, thickness));

                float result = 0;

                if (digit == 0)
                    result = max(max(max(segmentA, segmentB), max(segmentC, segmentD)), max(segmentE, segmentF));

                if (digit == 1)
                    result = max(segmentB, segmentC);

                if (digit == 2)
                    result = max(max(max(segmentA, segmentB), segmentG), max(segmentE, segmentD));

                if (digit == 3)
                    result = max(max(max(segmentA, segmentB), segmentG), max(segmentC, segmentD));

                if (digit == 4)
                    result = max(max(segmentF, segmentG), max(segmentB, segmentC));

                if (digit == 5)
                    result = max(max(max(segmentA, segmentF), segmentG), max(segmentC, segmentD));

                if (digit == 6)
                    result = max(max(max(segmentA, segmentF), max(segmentE, segmentD)), max(segmentC, segmentG));

                if (digit == 7)
                    result = max(max(segmentA, segmentB), segmentC);

                if (digit == 8)
                    result = max(max(max(segmentA, segmentB), max(segmentC, segmentD)), max(max(segmentE, segmentF), segmentG));

                if (digit == 9)
                    result = max(max(max(segmentA, segmentB), max(segmentC, segmentD)), max(segmentF, segmentG));

                return result;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 gridUV = IN.uv;

                gridUV.y += _Time.y * _NumberSpeed;

                float2 grid = gridUV * float2(_NumberColumns, _NumberRows);

                float2 cellID = floor(grid);
                float2 cellUV = frac(grid);

                float randomValue = random(cellID);
                int digit = (int)floor(randomValue * 10.0);

                float digitMask = drawDigit(cellUV, digit, _NumberThickness);

                float columnVariation = random(float2(cellID.x, 0.0));
                float fade = lerp(0.35, 1.0, columnVariation);

                float alpha = digitMask * _NumberAlpha * fade;

                half3 color = _NumberColor.rgb * digitMask * fade;

                return half4(color, alpha);
            }

            ENDHLSL
        }
    }
}
