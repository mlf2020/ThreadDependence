//
//  CustomThread.swift
//  UITextViewPlaceholder
//
//  Created by apple on 8/13/18.
//  Copyright © 2018 mlf. All rights reserved.
//

import UIKit

class CustomThread: Thread {
    
    deinit {
        print("---------\(classForCoder) is deinit--------")
    }
}
