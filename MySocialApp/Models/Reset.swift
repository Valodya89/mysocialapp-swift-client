import Foundation

public class Reset: Base {

    public var username: String?{
        get { return (super.getAttributeInstance("username") as! JSONableString?)?.string }
        set(login) { super.setStringAttribute(withName: "username", login) }
    }
    public var email: String?{
        get { return (super.getAttributeInstance("email") as! JSONableString?)?.string }
        set(email) { super.setStringAttribute(withName: "email", email) }
    }
    public var response: String?{
        get { return (super.getAttributeInstance("response") as! JSONableString?)?.string }
        set(response) { super.setStringAttribute(withName: "response", response) }
    }
    
    internal override func getAttributeCreationMethod(name: String) -> CreationMethod {
        switch name {
        case "username", "response", "email":
            return JSONableString().initAttributes
        default:
            return super.getAttributeCreationMethod(name: name)
        }
    }
    
    public required init() {
        super.init()
    }

    public init(username: String) {
        super.init()
        self.username = username
    }

}
