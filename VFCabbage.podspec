Pod::Spec.new do |s|

    s.name = 'VFCabbage'
    s.version = '0.5.1'
    s.summary = 'A high-level video composition framework build on top of AVFoundation. It\'s simple to use and easy to extend.'

    s.description  = <<-DESC
                    A high-level video composition framework build on top of AVFoundation. It\'s simple to use and easy to extend. Use it and make life easier if you are implementing video composition feature.
                    * Build result content objcet with only few step. 1. Create resource -> 2. Set configuration -> 3.Generate AVPlayerItem/AVAssetImageGenerator/AVExportSession
                    * Resouce: Support video, audio, and image. And resource is extendable, you can create your customized resource type. e.g gif image resource
                    * Video support: transform, speed, filter and so on. The configuration is extendable.
                    * Audio support: volume or process with audio raw data in real time. The configuration is extendable.
                    * Transition: Clips can transition with previous and next clip
                   DESC

    s.license = { :type => "MIT", :file => "LICENSE" }

    s.homepage = 'https://github.com/VideoFlint/Cabbage'

    s.author = { 'Vito' => 'vvitozhang@gmail.com' }

    s.platform = :ios, '9.0'
    s.swift_version = "4.2"

    s.source = { :git => 'https://github.com/VideoFlint/Cabbage.git', :tag => s.version.to_s }
    s.source_files = ['Cabbage/Sources/core/**/*.swift', 'Cabbage/Sources/**/*.swift']
    s.resource_bundles = { 'Cabbage' => 'Cabbage/Sources/Resource/*.mp4' }

    s.requires_arc = true
    s.frameworks = 'AVFoundation', 'CoreGraphics', 'CoreMedia', 'CoreImage', 'Accelerate'

end

