//
//  APIClient.swift
//  Where2Help
//
//  Created by Ramon Huidobro on 26/05/16.
//  Copyright © 2016 Where2Help. All rights reserved.
//

import Foundation
import Alamofire

struct APIClient {

  static func signUp(email: String, password: String, passwordConfirm: String, firstName: String, lastName: String, phoneNumber: String, success:(message: String) -> Void, failure:(message: String) -> Void) {
    let params = [
      "email": email,
      "password": password,
      "password_confirmation": passwordConfirm,
      "first_name": firstName,
      "last_name": lastName
    ]
    Alamofire.request(.POST, "\(Constants.Where2HelpAPIUrl)/users/register", parameters: params)
      .validate(statusCode: 200..<300)
      .responseJSON { response in
        switch response.result {
        case .Success:
          success(message: "We've sent you an email with a confirmation link!")
        case .Failure(_):
          failure(message: "Please make sure you entered the required fields\nor try again later")
        }
    }
  }

  static func login(email: String, password: String, success:(user: User) -> Void, failure:(message: String) -> Void) {
    let params = [
      "email": email,
      "password": password
    ]
    Alamofire.request(.POST, "\(Constants.Where2HelpAPIUrl)/users/login", parameters: params)
      .validate(statusCode: 200..<300)
      .responseJSON { response in
        switch response.result {
        case .Success:
          if let JSON = response.result.value {
            if let user = UserMapper.map(JSON as! NSDictionary), token = response.response?.allHeaderFields["TOKEN"] {
              user.password = password
              user.email = email
              UserManager.userSignedIn(user)
              updateTokenForUser(user, token: token as! String)
              success(user: user)
            }
          }
        case .Failure(let error):
          if let statusCode = response.response?.statusCode {
            switch statusCode {
            case 404:
              failure(message: "User email \(email) not found.")
            case 401:
              failure(message: "Incorrect email/password combination.")
            case 403:
              failure(message: "Please confirm your email address!")
            default:
              failure(message: "Could not sign you in right now. Please try again later")
            }
          }
          else {
            failure(message: error.localizedDescription)
          }
        }
    }
    print("Signing in with email: \(email) password: \(password)")
  }

  static func logout(user: User, success:() -> Void, failure:(message: String) -> Void) {
    let headers = headerForUser(user)
    Alamofire.request(.DELETE, "\(Constants.Where2HelpAPIUrl)/users/logout", headers: headers)
      .validate(statusCode: 200..<300)
      .responseJSON { response in
        switch response.result {
        case .Success:
          UserManager.logOut()
          success()
        case .Failure(let error):
          failure(message: error.localizedDescription)
        }
    }
  }

  static func optIn(user: User, shift: Shift, success:(json: AnyObject) -> Void, failure:(message: String) -> Void) {
    let headers = headerForUser(user)
    let params = [
      "shift_id": shift.ID
    ]
    Alamofire.request(.POST, "\(Constants.Where2HelpAPIUrl)/shifts/opt_in", headers: headers, parameters: params)
      .validate(statusCode: 200..<300)
      .responseJSON { response in
        if let token = response.response?.allHeaderFields["TOKEN"] {
          updateTokenForUser(user, token: token as! String)
          switch response.result {
          case .Success:
            if let JSON = response.result.value {
              success(json: JSON)
            }
          case .Failure(let error):
            failure(message: error.localizedDescription)
          }
        }
    }
  }

  static func optOut(user: User, shift: Shift, success:(json: AnyObject) -> Void, failure:(message: String) -> Void) {
    let headers = headerForUser(user)
    let params = [
      "shift_id": shift.ID
    ]
    Alamofire.request(.POST, "\(Constants.Where2HelpAPIUrl)/shifts/opt_out", headers: headers, parameters: params)
      .validate(statusCode: 200..<300)
      .responseJSON { response in
        if let token = response.response?.allHeaderFields["TOKEN"] {
          updateTokenForUser(user, token: token as! String)
          switch response.result {
          case .Success:
            if let JSON = response.result.value {
              success(json: JSON)
            }
          case .Failure(let error):
            failure(message: error.localizedDescription)
          }
        }
    }
  }

  static func getEvents(user: User, success:(json: NSArray) -> Void, failure:(message: String) -> Void) {
    let headers = headerForUser(user)
    let params = [
      "upcoming": true
    ]
    Alamofire.request(.GET, "\(Constants.Where2HelpAPIUrl)/events", headers: headers, parameters: params)
      .validate(statusCode: 200..<300)
      .responseJSON { response in
        if let token = response.response?.allHeaderFields["TOKEN"] {
          updateTokenForUser(user, token: token as! String)
          switch response.result {
          case .Success:
            if let JSON : NSArray = response.result.value as? NSArray {
              success(json: JSON)
            }
          case .Failure(let error):
            failure(message: error.localizedDescription)
          }
        }
    }
    
    return
  }
  
  private static func headerForUser(user: User) -> [String:String] {
    if let token = user.token {
      return [
        "Authorization": "Token token=\(token)"
      ]
    }
    return [:]
  }
  
  private static func updateTokenForUser(user: User, token: String) {
    user.token = token
  }
}
