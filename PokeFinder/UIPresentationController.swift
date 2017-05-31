//
//  UIPresentationController.swift
//  PokeFinder
//
//  Created by Mickaele Perez on 5/30/17.
//  Copyright © 2017 Code. All rights reserved.
//

import Foundation
import MapKit
import FirebaseDatabase

class UIPresentationController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pokemonPicker.delegate = self
        pokemonPicker.dataSource = self
        
    }
    
    @IBOutlet weak var pokemonPicker: UIPickerView!
    
    var selectedPokemonId: Int!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pokemon.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pokemon[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let pokeId = row
        selectedPokemonId = pokeId
    }
}
