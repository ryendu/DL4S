//
//  RecurrentLayerTypes.swift
//  DL4S
//
//  Created by Palle Klewitz on 01.03.19.
//

import Foundation


public class LSTM<Element: RandomizableType>: Layer, Codable {
    public var trainable: Bool = true
    
    let W_i: Tensor<Element>
    let W_o: Tensor<Element>
    let W_f: Tensor<Element>
    let W_c: Tensor<Element>
    
    let U_i: Tensor<Element>
    let U_o: Tensor<Element>
    let U_f: Tensor<Element>
    let U_c: Tensor<Element>
    
    let b_i: Tensor<Element>
    let b_o: Tensor<Element>
    let b_f: Tensor<Element>
    let b_c: Tensor<Element>
    
    public let hiddenSize: Int
    public let inputSize: Int
    
    public var parameters: [Tensor<Element>] {
        return trainable ? [
            W_i, U_i, b_i,
            W_o, U_o, b_o,
            W_f, U_f, b_f,
            W_c, U_c, b_c
            ] : []
    }
    
    public init(inputSize: Int, hiddenSize: Int) {
        W_i = Tensor<Element>(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        W_o = Tensor<Element>(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        W_f = Tensor<Element>(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        W_c = Tensor<Element>(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        
        U_i = Tensor<Element>(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        U_o = Tensor<Element>(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        U_f = Tensor<Element>(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        U_c = Tensor<Element>(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        
        b_i = Tensor<Element>(repeating: 0, shape: hiddenSize, requiresGradient: true)
        b_o = Tensor<Element>(repeating: 0, shape: hiddenSize, requiresGradient: true)
        b_f = Tensor<Element>(repeating: 0, shape: hiddenSize, requiresGradient: true)
        b_c = Tensor<Element>(repeating: 0, shape: hiddenSize, requiresGradient: true)
        
        W_i.tag = "W_i"
        W_o.tag = "W_o"
        W_f.tag = "W_f"
        W_c.tag = "W_c"
        U_i.tag = "U_i"
        U_o.tag = "U_o"
        U_f.tag = "U_f"
        U_c.tag = "U_c"
        b_i.tag = "b_i"
        b_o.tag = "b_o"
        b_f.tag = "b_f"
        b_c.tag = "b_c"
        
        self.hiddenSize = hiddenSize
        self.inputSize = inputSize
        
        for W in [W_i, W_o, W_f, W_c] {
            Random.fillNormal(W, stdev: (Element(1) / Element(inputSize)).sqrt())
        }
        
        for U in [U_i, U_o, U_f, U_c] {
            Random.fillNormal(U, stdev: (Element(1) / Element(hiddenSize)).sqrt())
        }
    }
    
    public func forward(_ inputs: [Tensor<Element>]) -> Tensor<Element> {
        // Expects one or three inputs
        // Either:
        // - input sequence, [initial hidden state and cell state] vector
        // - input sequence
        
        // Produces one hidden state vector for every input vector
        
        // Input shape: SequencLength x BatchSize x NumFeatures
        // Output shape: 2 x SequenceLength x BatchSize x HiddenSize
        
        precondition([1, 3].contains(inputs.count))
        
        let x = inputs[0]
        
        let seqlen = x.shape[0]
        let batchSize = x.shape[1]
        
        let h0: Tensor<Element>
        let c0: Tensor<Element>
        
        if inputs.count == 1 {
            h0 = Tensor(repeating: 0, shape: batchSize, hiddenSize)
            c0 = Tensor(repeating: 0, shape: batchSize, hiddenSize)
        } else {
            h0 = inputs[1][0]
            c0 = inputs[1][1]
        }
        
        var hiddenStates: [Tensor<Element>] = []
        var lstmStates: [Tensor<Element>] = []
        
        var h_p = h0
        var c_p = c0
        
        for i in 0 ..< seqlen {
            let x_t = x[i]
            
            let f_t = sigmoid(mmul(x_t, W_f) + mmul(h_p, U_f) + b_f)
            let i_t = sigmoid(mmul(x_t, W_i) + mmul(h_p, U_i) + b_i)
            let o_t = sigmoid(mmul(x_t, W_o) + mmul(h_p, U_o) + b_o)
            
            let c_t_partial_1 = f_t * c_p + i_t
            let c_t_partial_2 = tanh(mmul(x_t, W_c) + mmul(h_p, U_c) + b_c)
            let c_t = c_t_partial_1 * c_t_partial_2
            let h_t = o_t * tanh(c_t)
            
            h_p = h_t
            c_p = c_t
            
            hiddenStates.append(h_t)
            lstmStates.append(c_t)
        }
        
//        hiddenStates = hiddenStates.map {$0.view(as: 1, batchSize, self.hiddenSize)}
//        lstmStates = lstmStates.map {$0.view(as: 1, batchSize, self.hiddenSize)}
        
        //return stack(stack(hiddenStates), stack(lstmStates))
        return h_p
    }
}


public class GRU<Element: RandomizableType>: Layer, Codable {
    let W_z: Tensor<Element>
    let W_r: Tensor<Element>
    let W_h: Tensor<Element>
    
    let U_z: Tensor<Element>
    let U_r: Tensor<Element>
    let U_h: Tensor<Element>
    
    let b_z: Tensor<Element>
    let b_r: Tensor<Element>
    let b_h: Tensor<Element>
    
    public var parameters: [Tensor<Element>] {
        return trainable ? [W_z, W_r, W_h, U_z, U_r, U_h, b_z, b_r, b_h] : []
    }
    
    public var trainable: Bool = true
    
    public let hiddenSize: Int
    public let inputSize: Int
    
    public init(inputSize: Int, hiddenSize: Int) {
        self.inputSize = inputSize
        self.hiddenSize = hiddenSize
        
        W_z = Tensor(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        W_r = Tensor(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        W_h = Tensor(repeating: 0, shape: inputSize, hiddenSize, requiresGradient: true)
        
        U_z = Tensor(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        U_r = Tensor(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        U_h = Tensor(repeating: 0, shape: hiddenSize, hiddenSize, requiresGradient: true)
        
        b_z = Tensor(repeating: 0, shape: hiddenSize, requiresGradient: true)
        b_r = Tensor(repeating: 0, shape: hiddenSize, requiresGradient: true)
        b_h = Tensor(repeating: 0, shape: hiddenSize, requiresGradient: true)
        
        W_z.tag = "W_z"
        W_r.tag = "W_r"
        W_h.tag = "W_h"
        U_z.tag = "U_z"
        U_r.tag = "U_r"
        U_h.tag = "U_h"
        b_z.tag = "b_z"
        b_r.tag = "b_r"
        b_h.tag = "b_h"
        
        for W in [W_z, W_r, W_h] {
            Random.fillNormal(W, stdev: (Element(1) / Element(inputSize)).sqrt())
        }
        
        for U in [U_z, U_r, U_h] {
            Random.fillNormal(U, stdev: (Element(1) / Element(hiddenSize)).sqrt())
        }
    }
    
    public func forward(_ inputs: [Tensor<Element>]) -> Tensor<Element> {
        precondition(1 ... 2 ~= inputs.count)
        
        // Input: Either [input, hidden state] or input
        // Input shape: SequencLength x BatchSize x NumFeatures
        
        let h_0: Tensor<Element>
        let x = inputs[0]
        
        let seqlen = x.shape[0]
        let batchSize = x.shape[1]
        
        if inputs.count == 1 {
            h_0 = Tensor(repeating: 0, shape: batchSize, hiddenSize)
        } else {
            h_0 = inputs[1]
        }
        
        var hiddenStates: [Tensor<Element>] = []
        var h_p = h_0
        
        for i in 0 ..< seqlen {
            let x_t = x[i]
            
            let z_t = sigmoid(mmul(x_t, W_z) + mmul(h_p, U_z) + b_z)
            let r_t = sigmoid(mmul(x_t, W_r) + mmul(h_p, U_r) + b_r)
            
            let h_t_partial_1 = (1 - z_t) * h_p
            let h_t_partial_2 = tanh(mmul(x_t, W_h) + mmul(r_t * h_p, U_h) + b_h)
            
            let h_t = h_t_partial_1 + z_t * h_t_partial_2
            h_p = h_t
            
            hiddenStates.append(h_t)
        }
        
        // Output shape: 1 x SequenceLength x BatchSize x HiddenSize
        // return stack(hiddenStates).view(as: 1, seqlen, batchSize, hiddenSize)
        
        // Output shape: BatchSize x HiddenSize
        return h_p
    }
}

public class TakeLastHiddenState<Element: NumericType>: Layer {
    public var trainable: Bool {
        get {
            return false
        }
        set {
            // noop
        }
    }
    
    public var parameters: [Tensor<Element>] {
        return []
    }
    
    public init() {}
    
    public func forward(_ inputs: [Tensor<Element>]) -> Tensor<Element> {
        precondition(inputs.count == 1)
        
        let sequence = inputs[0]
        
        return sequence[0, sequence.shape[1]-1]
    }
}