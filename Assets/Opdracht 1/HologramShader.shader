Shader "Custom/HologramShader"
{
    Properties
    {
        _MainColor("Main Color", Color) = (0, 1, 1, 1)
        _RimColor("Rim Color", Color) = (0, 1, 1, 1)

        _RimPower("Rim Power", Range(0.5, 10)) = 4
        
        _ScanlineSpeed("Scanline Speed", Float) = 2
        _ScanlineDensity("Scanline Density", Float) = 50
        
        _Transparency("Transparency", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForward"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        Cull Front
        ZWrite Off

        Pass
        {
            Name "HologramPass"

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

            half4 _MainColor;
            half4 _RimColor;

            float _RimPower;

            float _ScanlineSpeed;
            float _ScanlineDensity;

            float _Transparency;

            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 worldPos = TransformObjectToWorld(IN.positionOS.xyz);

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.worldPos = worldPos;
                OUT.worldNormal = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.viewDir = normalize(GetWorldSpaceViewDir(worldPos));

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float rim = 1 - saturate(dot(IN.viewDir, IN.worldNormal));
                rim = pow(rim, _RimPower);

                float scanLine = sin(IN.worldPos.y * _ScanlineDensity + _Time.y * _ScanlineSpeed);
                scanLine = scanLine * 0.5 + 0.5;

                float pulse = sin(_Time.y * 2) * 0.5 + 0.5;

                float hologram = rim + scanLine * 0.3 + pulse * 0.2;

                half3 finalColor = _MainColor.rgb * hologram + _RimColor.rgb * rim;

                return half4(finalColor, _Transparency);
            }

            ENDHLSL
        }

        Cull Back

        Pass 
        {
            
        }

        // UsePass "Custom/HologramShader/HologramPass"
    }
}