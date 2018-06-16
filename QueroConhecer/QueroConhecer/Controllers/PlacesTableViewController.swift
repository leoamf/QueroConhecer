//
//  PlacesTableViewController.swift
//  QueroConhecer
//
//  Created by aluno on 02/06/18.
//  Copyright © 2018 aluno. All rights reserved.
//

import UIKit
class PlacesTableViewController: UITableViewController {
    // estrutura para armazenar os Places
    var places: [Place] = []
    
    // persistence
    let ud = UserDefaults.standard
    var lbNoPlaces: UILabel!

    @objc func loadPlaces() {
        
        if let placeData = ud.data(forKey: "places") {
            do {
                places = try JSONDecoder().decode([Place].self, from: placeData)
                tableView.reloadData()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        lbNoPlaces = UILabel()
        lbNoPlaces.text = "Cadastre os locais que deseja conhecer\nclicando no botão + acima."
        lbNoPlaces.textAlignment = .center
        lbNoPlaces.numberOfLines = 0
        loadPlaces()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    @objc func showAll(){
        performSegue(withIdentifier: "mapSegue", sender: places)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if places.count > 0 {
            let btShowAll = UIBarButtonItem(title: "Exibir todos", style: .plain, target: self, action: #selector(showAll))
            navigationItem.leftBarButtonItem = btShowAll
            tableView.backgroundView = nil
        } else {
            tableView.backgroundView = lbNoPlaces
            navigationItem.leftBarButtonItem = nil
        }
        return places.count
    }
    
    func savePlaces() {
        do {
            let json = try JSONEncoder().encode(places)
            self.ud.setValue(json, forKey: "places")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // Configure the cell...
        let place = places[indexPath.row]
        cell.textLabel?.text = place.name
        return cell
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "finderSegue" {
            let vc = segue.destination as! PlaceFinderViewController
            vc.delegate = self
        }else if segue.identifier! == "mapSegue" {
            print("-> map segue")
            let vc = segue.destination as! MapViewController
            switch sender {
            case let place as Place:
                vc.places = [place]
            default:
                vc.places = places
            }
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = places[indexPath.row]
        performSegue(withIdentifier: "mapSegue", sender: place)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle : UITableViewCellEditingStyle,forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            places.remove(at: indexPath.row)
            savePlaces()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}
extension PlacesTableViewController: PlaceFinderDelegate {
    
    func addPlace(_ place: Place) {
        // evita que um place (mesma longitude e latitude) seja adicionado
        // TIP. : ver regra no model de Place
        if !places.contains(place) {
            // save
            self.places.append(place)
            self.savePlaces()
            self.tableView.reloadData()
        }
        
        
    }
}
