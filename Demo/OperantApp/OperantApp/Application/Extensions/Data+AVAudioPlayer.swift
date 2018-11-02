//
//  Data+AVAudioPlayer.swift
//  OperantApp
//
//  Created by Yuto Mizutani on 2018/10/26.
//  Copyright © 2018 Yuto Mizutani. All rights reserved.
//

import AVFoundation

extension Data {
    func player(type: String) -> AVAudioPlayer? {
        return try? AVAudioPlayer(
            data: self,
            fileTypeHint: type
        )
    }
}
