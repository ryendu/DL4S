//
//  ConvTests.swift
//  DL4STests
//
//  Created by Palle Klewitz on 13.03.19.
//  Copyright (c) 2019 - Palle Klewitz
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import XCTest
import DL4S
#if canImport(AppKit)
import AppKit

extension NSImage {
    func save(to path: String, type: NSBitmapImageRep.FileType = .png) throws {
        guard let imgData = self.tiffRepresentation, let rep = NSBitmapImageRep(data: imgData) else {
            throw NSError()
        }
        guard let png = rep.representation(using: type, properties: [:]) else {
            throw NSError()
        }
        try png.write(to: URL(fileURLWithPath: path))
    }
}
#endif

class ConvTests: XCTestCase {
    func testIm2col() {
        let a = Tensor<Float, CPU>((0 ..< 16).map(Float.init), shape: 1, 1, 4, 4)
        let c = a.repeated(4)
        let d = c * Tensor<Float, CPU>([1,0.5,0.25,0.125]).view(as: 4, 1, 1, 1)
        
        print(d)
        let result = d.img2col(kernelWidth: 3, kernelHeight: 3, padding: 0, stride: 1)
        print(result.permuted(to: 1, 0))
    }
    
    func testIm2colPerformance() {
        let a = Tensor<Float, CPU>(uniformlyDistributedWithShape: [64, 32, 128, 128])
        
        measure {
            _ = a.img2col(kernelWidth: 3, kernelHeight: 3, padding: 0, stride: 1)
        }
    }
    
    func testConv2d1() {
        let a = Tensor<Float, CPU>((0 ..< 16).map(Float.init), shape: 1, 1, 4, 4)
        let c = a.repeated(4)
        let d = c * Tensor<Float, CPU>([1,0.5,0.25,0.125]).view(as: 4, 1, 1, 1)
        
        let filters = Tensor<Float, CPU>([
            [
                [[1]]
            ],
            [
                [[-1]]
            ]
        ])
        
        print(d.convolved2d(filters: filters))
    }
    
    func testConv2d() {
        let filters = Tensor<Float, CPU>([
            [
                [[1, 2, 1],
                 [2, 4, 2],
                 [1, 2, 1]]
            ],
            [
                [[-1, 0, 1],
                [-2, 0, 2],
                [-1, 0, 1]]
            ]
        ]) / Tensor<Float, CPU>([16, 4]).view(as: -1, 1, 1, 1)
        
        print(filters.shape)
        
        let ((images, _), _) = MNISTTests.loadMNIST(from: MNIST_PATH, type: Float.self, device: CPU.self)
        
        let batch = images[0 ..< 64]
        
        let filtered = batch.convolved2d(filters: filters)
        
        #if canImport(AppKit) && false
        for i in 0 ..< batch.shape[0] {
            let src = batch[i]
            let dst = filtered[i]
            
            let srcImg = NSImage(src)
            try? srcImg?.save(to: "/Users/Palle/Desktop/conv/src_\(i).png")
            
            for j in 0 ..< dst.shape[0] {
                let dstImg = NSImage(dst[j].permuted(to: 1, 0).unsqueezed(at: 0))
                try? dstImg?.save(to: "/Users/Palle/Desktop/conv/dst_\(i)_\(j)a.png")
            }
        }
        #endif
    }
    
    func testConv1d() {
        let filters = Tensor<Float, CPU>([0.02641911, 0.70953383, 0.42951898, 0.58568196, 0.50831411, 0.13808442]).view(as: 2, 1, 3)

        //testSequenceData shape => [batchSize = 2, channels = 1, size = 9]
        let testSequenceData = Tensor<Float, CPU>([0.52582376, 0.92104604, 0.46794182, 0.08924296, 0.16710744, 0.37407358, 0.04043267, 0.25526662,  0.89840653,  0.22725283, 0.68823759, 0.86775579, 0.06474228, 0.70579868, 0.99648027,0.51797662, 0.03736867, 0.19278374]).view(as: [2,1,9])
        let filtered = testSequenceData.convolved1d(filters: filters, padding: 2)
        print("Finished Convolution process with --- \n res: \(filtered), \n res shape: \(filtered.shape), \n inp shape: \(testSequenceData.shape), \n filters shape: \(filters.shape); kernel size: \(filters.shape[2])")
        
    }
    
    func testTransposedConv1d() {
        let filters = Tensor<Float, CPU>([0.02641911, 0.70953383, 0.42951898, 0.58568196, 0.50831411, 0.13808442]).view(as: 2, 1, 3)
        //testSequenceData shape => [batchSize = 2, channels = 1, size = 9]
        let testSequenceData = Tensor<Float, CPU>([0.52582376, 0.92104604, 0.46794182, 0.08924296, 0.16710744, 0.37407358, 0.04043267, 0.25526662,  0.89840653,  0.22725283, 0.68823759, 0.86775579, 0.06474228, 0.70579868, 0.99648027,0.51797662, 0.03736867, 0.19278374]).view(as: [2,1,9])
        let filtered = testSequenceData.transposedConvolved1d(filters: filters, inset: 0)
        print("Finished Transposed Convolution process with --- \n res: \(filtered), \n res shape: \(filtered.shape), \n inp shape: \(testSequenceData.shape), \n filters shape: \(filters.shape); kernel size: \(filters.shape[2])")
        
    }
    
    func testTransposedConv2d() {
        let filters = Tensor<Float, CPU>([
            [
                [[1, 2, 1],
                 [2, 4, 2],
                 [1, 2, 1]]
            ],
            [
                [[-1, 0, 1],
                [-2, 0, 2],
                [-1, 0, 1]]
            ]
        ]) / Tensor<Float, CPU>([4, 1]).view(as: -1, 1, 1, 1)
        
        let ((images, _), _) = MNISTTests.loadMNIST(from: MNIST_PATH, type: Float.self, device: CPU.self)
        let batch = images[0 ..< 64]
        
        let filtered = batch.transposedConvolved2d(filters: filters, stride: 2)
        
        #if canImport(AppKit) && false
        for i in 0 ..< batch.shape[0] {
            let src = batch[i]
            let dst = filtered[i]
            
            let srcImg = NSImage(src.view(as: [28, 28]).permuted(to: 1, 0).unsqueezed(at: 0))
            try? srcImg?.save(to: "/Users/Palle/Desktop/conv/\(i)_src.png")
            
            for j in 0 ..< dst.shape[0] {
                let dstImg = NSImage(dst[j].permuted(to: 1, 0).unsqueezed(at: 0))
                try? dstImg?.save(to: "/Users/Palle/Desktop/conv/\(i)_\(j)_t.png")
            }
        }
        #endif
    }
}
