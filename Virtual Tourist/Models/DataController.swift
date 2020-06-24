//
//  DataController.swift
//  Virtual Tourist
//
//  Created by mahmoud diab on 6/23/20.
//  Copyright © 2020 Diab. All rights reserved.
//

import Foundation
import CoreData

//MARK:- steps to setup Data Controller
/*
 
 1-  inistantiate persistent controller obj.
 2-  initialize Data controller class by its model.
 3-  setup view context of type NSManagedObjectContext that deal with all managed objects.
 4-  setup load func that loads the persistent store.
 5-  setup save function to  Persists the main context changes, if any.
 6-  create instance of data controller at app delegate and initialize it by virtual_tourist     model.
 */

class DataController {
    // 1
    let persistentContainer:NSPersistentContainer
    // 2
    init(modelName:String) {
        self.persistentContainer = NSPersistentContainer(name: "Virtual_Tourist")
    }
    // 3
    var viewContext :NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    // 4
    
    /// - Parameter completionHandler: the completion handler called when core data is loaded,
    ///                                with an error, if occurred.
    func load(_ completionHandler: @escaping (NSPersistentStoreDescription?, Error?) -> Void) {
        persistentContainer.loadPersistentStores(completionHandler: completionHandler)
    }
    
    /// 5
    func save() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
}
