using ResumableFunctions

"""
Generator that yields list of (left, top, bucket_width, bucket_height)
"""

@resumable function buckets_reading_order(image_width, image_height, crop_window)

    @assert image_width % BUCKET_SIZE == 0
    @assert image_height % BUCKET_SIZE == 0

    # Reading order, i.e. top to bottom, left to right
    for top in 0:BUCKET_SIZE:image_height-1
        for left in 0:BUCKET_SIZE:image_width-1
        
            if crop_window !== nothing
                if left+width-1 < crop_window[1] || left > crop_window[3]
                    continue
                end
                if top+height-1 < crop_window[2] || top > crop_window[4]
                    continue
                end
            end
        
            @yield (left, top, BUCKET_SIZE, BUCKET_SIZE)
        end
    end
end