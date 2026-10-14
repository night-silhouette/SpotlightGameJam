shader_type canvas_item;

// 易碎裂纹与微光提示
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float crack_width : hint_range(0.01, 0.5) = 0.22;
uniform vec4 crack_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float crack_scale : hint_range(1.0, 50.0) = 14.0;

// 消解/瓦解控制 (0.0 = 完整, 1.0 = 完全瓦解)
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.06;
uniform vec4 edge_color : source_color = vec4(0.95, 0.65, 0.3, 1.0); // 风化/瓦解边缘泛光

// 伪随机生成哈希
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 基础值噪声
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Voronoi 蜂窝裂隙算法（模拟岩石石纹、脆弱网状裂痕）
float voronoi_cracks(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float md1 = 8.0;
    float md2 = 8.0;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(hash(n + g), hash(n + g + 13.5));
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md1) {
                md2 = md1;
                md1 = d;
            } else if (d < md2) {
                md2 = d;
            }
        }
    }
    // 单元边缘距离，形成裂隙线
    return clamp(sqrt(md2) - sqrt(md1), 0.0, 1.0);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    if (tex.a <= 0.001) {
        discard;
    }

    // 1. 易碎网状裂纹表现
    float crack_dist = voronoi_cracks(UV * crack_scale);
    // 加宽裂隙阈值，形成清晰明显的裂口
    float crack_mask = 1.0 - smoothstep(0.0, crack_width, crack_dist);
    crack_mask = pow(crack_mask, 0.8) * crack_intensity;

    // 将裂纹融入原有纹理
    vec3 base_rgb = mix(tex.rgb, crack_color.rgb, crack_mask);

    // 2. 瓦解/消融计算
    // 融合噪声与 Voronoi 碎块，使瓦解呈现碎块剥离+颗粒风化效果
    float n1 = noise(UV * 12.0);
    float n2 = noise(UV * 28.0);
    float n_val = mix(n1, n2, 0.35);
    float break_noise = mix(n_val, crack_dist, 0.4);

    // 根据消融进度与噪声对比
    float cutoff = dissolve_progress;
    
    if (dissolve_progress > 0.0) {
        if (break_noise < cutoff) {
            discard;
        }

        // 瓦解边缘发光/沙化碎边
        float edge = smoothstep(cutoff, cutoff + edge_width, break_noise);
        base_rgb = mix(edge_color.rgb, base_rgb, edge);
    }

    COLOR = vec4(base_rgb, tex.a);
}
