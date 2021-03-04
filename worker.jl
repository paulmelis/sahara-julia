function in_shadow(scene_primitives, ray)

    for prim in scene_primitives
        if intersection(prim, ray) !== nothing
            return true
        end
    end

    return false
    
end

function compute_radiance(scene_primitives::Vector{Primitive}, lights::Vector{Light}, ray::Ray, ray_stats::RayStats, indirect=true) ::vec3

    #print('compute_radiance', ray)
    
    num_indirect_rays = 0
    num_shadow_rays = 0
    
    best_ip::Union{IntersectionPoint, Nothing} = nothing
    best_prim::Union{Primitive, Nothing} = nothing
    
    for prim in scene_primitives

        ip = intersection(prim, ray)
        if ip === nothing
            continue
        end

        # Have hit
        if ip.t < ray.t_max
            # New closest hit      
            ray = Ray(ray, ip.t)
            best_ip = ip
            best_prim = prim
        end
        
    end

    if best_ip === nothing
        #print('No object intersection')
        return vec3(0, 0, 0)
    end

    #println("HIT", ray, best_prim, best_ip.t, best_ip.p, best_ip.n)
    ip_p = best_ip.p
    ip_n = best_ip.n

    # Shade by normal
    #return ip_n

    # Simple direct lighting, with shadowing
    # Add ambient and light terms
    # k_a * I_a + sum(m in lights} { k_d * (L_n * N) * i_m,d }
    # L_n = |light position - surface point|

    radiance = vec3(0, 0, 0)

    for light in lights

        light_position = get_random_position(light)

        # Trace shadow ray
        L = light_position - ip_p
        Ln = normalized(L)
        sray = Ray(ip_p + 0.0001f0*Ln, L, 1.0f0)
        num_shadow_rays += 1

        if in_shadow(scene_primitives, sray)
            continue
        end

        f = dot(Ln, ip_n) * strength(light)
        if f > 0
            radiance += vec3(f, f, f)
        end
            
    end

    #print('after adding direct light:', radiance)

    if indirect
        # Sample indirect contribution using a single ray in a random direction around
        # the normal. Assumes lambertian surface.

        MATERIAL_REFLECTIVITY = 0.75f0

        # Compute indirect lighting, by trace a reflected ray (depending on russian roulette)
        if rand() < MATERIAL_REFLECTIVITY

            eta1 = rand()
            eta2 = rand()
            theta = acos(sqrt(eta1))
            phi = 2*pi*eta2

            u, v = create_orthonormal_basis(ip_n)

            sin_theta = sin(theta)
            
            d = u * cos(phi) * sin_theta + v * sin(phi) * sin_theta + ip_n * cos(theta)
            d = normalized(d)
            #assert(d * ip_n >= 0.0)

            r2 = Ray(ip_p + d*0.0001f0, d)

            #print('tracing indirect ray', r2)

            rad2 = compute_radiance(scene_primitives, lights, r2, ray_stats, indirect)
            radiance += rad2 * dot(ip_n, d) / MATERIAL_REFLECTIVITY

            num_indirect_rays += 1
            
        end

        #else:
            #print('NOT tracing indirect ray')
    end
    
    ray_stats.num_indirect_rays += num_indirect_rays
    ray_stats.num_shadow_rays += num_shadow_rays

    #print('returning (unclamped)', radiance)

    return clamp.(radiance, 0.0f0, 1.0f0)
end

function process_bucket(scene_data, bucket)

    ray_stats = RayStats()

    bucket_left, bucket_top, bucket_width, bucket_height = bucket
    crop_window = scene_data.crop_window
    
    camera = scene_data.camera
    camera_position = camera.position
    image_plane_topleft = camera.image_plane_topleft
    pixel_step_right = camera.pixel_step_right
    pixel_step_down = camera.pixel_step_down

    compute_radiance_indirect = scene_data.integrator == "path"
    
    pixel_sample_locations = scene_data.pixel_sample_locations
    num_samples = length(pixel_sample_locations)
    

    # Mini-framebuffer to hold this bucket's final pixel values    
    pixels = zeros(RGB{Float32}, bucket_width, bucket_height) 
    
    # Loop over all pixels in the bucket
    for j in 0:bucket_height-1

        if crop_window !== nothing
            if bucket_top+j < crop_window[2] || bucket_top+j > crop_window[4]
                continue
            end
        end

        for i in 0:bucket_width-1

            if crop_window !== nothing
                if bucket_left+i < crop_window[1] || bucket_left+i > crop_window[3]
                    continue
                end
            end

            pixel_topleft = (image_plane_topleft 
                + pixel_step_right * (bucket_left+i) 
                + pixel_step_down * (bucket_top+j))
                
            radiance_sum = vec3(0, 0, 0)

            for sloc in pixel_sample_locations

                # Compute corresponding point on image plane
                image_plane_point = pixel_topleft + sloc[1]*pixel_step_right + sloc[2]*pixel_step_down

                # Initialize the ray
                # We shoot primary rays (all rays originate at the camera position)
                r = Ray(camera_position, image_plane_point - camera_position, INFINITY)

                # Trace it
                # XXX store local prims
                radiance_sum += compute_radiance(scene_data.primitives, scene_data.lights, r, ray_stats, compute_radiance_indirect)
                
            end

            color = radiance_sum / num_samples
            pixels[j+1,i+1] = RGB(color[1], color[2], color[3])

            ray_stats.num_primary_rays += num_samples
            
        end

    end

    return pixels, ray_stats
end
    