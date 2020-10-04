import Foundation

@objc extension NSColor {
    var serializedString: String {
        guard let export = self.usingColorSpace(.deviceRGB) else { return "0:0:0:1" }
        
        return String(format: "%lf:%lf:%lf:%lf",
                      export.redComponent,
                      export.greenComponent,
                      export.blueComponent,
                      export.alphaComponent)
    }
    
    var descriptionString: String {
        let r: Int
        let g: Int
        let b: Int
        
        if let export = usingColorSpace(.deviceRGB) {
            r = Int(round(export.redComponent * 255))
            g = Int(round(export.greenComponent * 255))
            b = Int(round(export.blueComponent * 255))
        } else {
            r = 0
            g = 0
            b = 0
        }
        
        return String(format: "#%02lx%02lx%02lx (R=%ld, G=%ld, B=%ld)", r, g, b, r, g, b).uppercased()
    }
    
    convenience init?(serializedString string: String) {
        let chunks = string.components(separatedBy: ":")
        
        guard chunks.count == 4 else { return nil }
        let components = chunks.map { CGFloat(Double($0) ?? 0) }
        
        self.init(deviceRed: components[0],
                  green: components[1],
                  blue: components[2],
                  alpha: components[3])
    }
    
    convenience init?(cssName: String) {
        switch cssName.lowercased() {
        case "aliceblue":
            self.init(deviceRed: 0.941176470588235, green: 0.972549019607843, blue: 1.0, alpha: 1.0)
        case "antiquewhite":
            self.init(deviceRed: 0.980392156862745, green: 0.92156862745098, blue: 0.843137254901961, alpha: 1.0)
        case "aqua":
            self.init(deviceRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case "aquamarine":
            self.init(deviceRed: 0.498039215686275, green: 1.0, blue: 0.831372549019608, alpha: 1.0)
        case "azure":
            self.init(deviceRed: 0.941176470588235, green: 1.0, blue: 1.0, alpha: 1.0)
        case "beige":
            self.init(deviceRed: 0.96078431372549, green: 0.96078431372549, blue: 0.862745098039216, alpha: 1.0)
        case "bisque":
            self.init(deviceRed: 1.0, green: 0.894117647058824, blue: 0.768627450980392, alpha: 1.0)
        case "black":
            self.init(deviceRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case "blanchedalmond":
            self.init(deviceRed: 1.0, green: 0.92156862745098, blue: 0.803921568627451, alpha: 1.0)
        case "blue":
            self.init(deviceRed: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case "blueviolet":
            self.init(deviceRed: 0.541176470588235, green: 0.168627450980392, blue: 0.886274509803922, alpha: 1.0)
        case "brown":
            self.init(deviceRed: 0.647058823529412, green: 0.164705882352941, blue: 0.164705882352941, alpha: 1.0)
        case "burlywood":
            self.init(deviceRed: 0.870588235294118, green: 0.72156862745098, blue: 0.529411764705882, alpha: 1.0)
        case "cadetblue":
            self.init(deviceRed: 0.372549019607843, green: 0.619607843137255, blue: 0.627450980392157, alpha: 1.0)
        case "chartreuse":
            self.init(deviceRed: 0.498039215686275, green: 1.0, blue: 0.0, alpha: 1.0)
        case "chocolate":
            self.init(deviceRed: 0.823529411764706, green: 0.411764705882353, blue: 0.117647058823529, alpha: 1.0)
        case "coral":
            self.init(deviceRed: 1.0, green: 0.498039215686275, blue: 0.313725490196078, alpha: 1.0)
        case "cornflowerblue":
            self.init(deviceRed: 0.392156862745098, green: 0.584313725490196, blue: 0.929411764705882, alpha: 1.0)
        case "cornsilk":
            self.init(deviceRed: 1.0, green: 0.972549019607843, blue: 0.862745098039216, alpha: 1.0)
        case "crimson":
            self.init(deviceRed: 0.862745098039216, green: 0.0784313725490196, blue: 0.235294117647059, alpha: 1.0)
        case "cyan":
            self.init(deviceRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case "darkblue":
            self.init(deviceRed: 0.0, green: 0.0, blue: 0.545098039215686, alpha: 1.0)
        case "darkcyan":
            self.init(deviceRed: 0.0, green: 0.545098039215686, blue: 0.545098039215686, alpha: 1.0)
        case "darkgoldenrod":
            self.init(deviceRed: 0.72156862745098, green: 0.525490196078431, blue: 0.0431372549019608, alpha: 1.0)
        case "darkgray":
            self.init(deviceRed: 0.662745098039216, green: 0.662745098039216, blue: 0.662745098039216, alpha: 1.0)
        case "darkgreen":
            self.init(deviceRed: 0.0, green: 0.392156862745098, blue: 0.0, alpha: 1.0)
        case "darkkhaki":
            self.init(deviceRed: 0.741176470588235, green: 0.717647058823529, blue: 0.419607843137255, alpha: 1.0)
        case "darkmagenta":
            self.init(deviceRed: 0.545098039215686, green: 0.0, blue: 0.545098039215686, alpha: 1.0)
        case "darkolivegreen":
            self.init(deviceRed: 0.333333333333333, green: 0.419607843137255, blue: 0.184313725490196, alpha: 1.0)
        case "darkorange":
            self.init(deviceRed: 1.0, green: 0.549019607843137, blue: 0.0, alpha: 1.0)
        case "darkorchid":
            self.init(deviceRed: 0.6, green: 0.196078431372549, blue: 0.8, alpha: 1.0)
        case "darkred":
            self.init(deviceRed: 0.545098039215686, green: 0.0, blue: 0.0, alpha: 1.0)
        case "darksalmon":
            self.init(deviceRed: 0.913725490196078, green: 0.588235294117647, blue: 0.47843137254902, alpha: 1.0)
        case "darkseagreen":
            self.init(deviceRed: 0.56078431372549, green: 0.737254901960784, blue: 0.56078431372549, alpha: 1.0)
        case "darkslateblue":
            self.init(deviceRed: 0.282352941176471, green: 0.23921568627451, blue: 0.545098039215686, alpha: 1.0)
        case "darkslategray":
            self.init(deviceRed: 0.184313725490196, green: 0.309803921568627, blue: 0.309803921568627, alpha: 1.0)
        case "darkturquoise":
            self.init(deviceRed: 0.0, green: 0.807843137254902, blue: 0.819607843137255, alpha: 1.0)
        case "darkviolet":
            self.init(deviceRed: 0.580392156862745, green: 0.0, blue: 0.827450980392157, alpha: 1.0)
        case "deeppink":
            self.init(deviceRed: 1.0, green: 0.0784313725490196, blue: 0.576470588235294, alpha: 1.0)
        case "deepskyblue":
            self.init(deviceRed: 0.0, green: 0.749019607843137, blue: 1.0, alpha: 1.0)
        case "dimgray":
            self.init(deviceRed: 0.411764705882353, green: 0.411764705882353, blue: 0.411764705882353, alpha: 1.0)
        case "dodgerblue":
            self.init(deviceRed: 0.117647058823529, green: 0.564705882352941, blue: 1.0, alpha: 1.0)
        case "firebrick":
            self.init(deviceRed: 0.698039215686274, green: 0.133333333333333, blue: 0.133333333333333, alpha: 1.0)
        case "floralwhite":
            self.init(deviceRed: 1.0, green: 0.980392156862745, blue: 0.941176470588235, alpha: 1.0)
        case "forestgreen":
            self.init(deviceRed: 0.133333333333333, green: 0.545098039215686, blue: 0.133333333333333, alpha: 1.0)
        case "fuchsia":
            self.init(deviceRed: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case "gainsboro":
            self.init(deviceRed: 0.862745098039216, green: 0.862745098039216, blue: 0.862745098039216, alpha: 1.0)
        case "ghostwhite":
            self.init(deviceRed: 0.972549019607843, green: 0.972549019607843, blue: 1.0, alpha: 1.0)
        case "gold":
            self.init(deviceRed: 1.0, green: 0.843137254901961, blue: 0.0, alpha: 1.0)
        case "goldenrod":
            self.init(deviceRed: 0.854901960784314, green: 0.647058823529412, blue: 0.125490196078431, alpha: 1.0)
        case "gray":
            self.init(deviceRed: 0.501960784313725, green: 0.501960784313725, blue: 0.501960784313725, alpha: 1.0)
        case "green":
            self.init(deviceRed: 0.0, green: 0.501960784313725, blue: 0.0, alpha: 1.0)
        case "greenyellow":
            self.init(deviceRed: 0.67843137254902, green: 1.0, blue: 0.184313725490196, alpha: 1.0)
        case "honeydew":
            self.init(deviceRed: 0.941176470588235, green: 1.0, blue: 0.941176470588235, alpha: 1.0)
        case "hotpink":
            self.init(deviceRed: 1.0, green: 0.411764705882353, blue: 0.705882352941177, alpha: 1.0)
        case "indianred ":
            self.init(deviceRed: 0.803921568627451, green: 0.36078431372549, blue: 0.36078431372549, alpha: 1.0)
        case "indigo ":
            self.init(deviceRed: 0.294117647058824, green: 0.0, blue: 0.509803921568627, alpha: 1.0)
        case "ivory":
            self.init(deviceRed: 1.0, green: 1.0, blue: 0.941176470588235, alpha: 1.0)
        case "khaki":
            self.init(deviceRed: 0.941176470588235, green: 0.901960784313726, blue: 0.549019607843137, alpha: 1.0)
        case "lavender":
            self.init(deviceRed: 0.901960784313726, green: 0.901960784313726, blue: 0.980392156862745, alpha: 1.0)
        case "lavenderblush":
            self.init(deviceRed: 1.0, green: 0.941176470588235, blue: 0.96078431372549, alpha: 1.0)
        case "lawngreen":
            self.init(deviceRed: 0.486274509803922, green: 0.988235294117647, blue: 0.0, alpha: 1.0)
        case "lemonchiffon":
            self.init(deviceRed: 1.0, green: 0.980392156862745, blue: 0.803921568627451, alpha: 1.0)
        case "lightblue":
            self.init(deviceRed: 0.67843137254902, green: 0.847058823529412, blue: 0.901960784313726, alpha: 1.0)
        case "lightcoral":
            self.init(deviceRed: 0.941176470588235, green: 0.501960784313725, blue: 0.501960784313725, alpha: 1.0)
        case "lightcyan":
            self.init(deviceRed: 0.87843137254902, green: 1.0, blue: 1.0, alpha: 1.0)
        case "lightgoldenrodyellow":
            self.init(deviceRed: 0.980392156862745, green: 0.980392156862745, blue: 0.823529411764706, alpha: 1.0)
        case "lightgray":
            self.init(deviceRed: 0.827450980392157, green: 0.827450980392157, blue: 0.827450980392157, alpha: 1.0)
        case "lightgreen":
            self.init(deviceRed: 0.564705882352941, green: 0.933333333333333, blue: 0.564705882352941, alpha: 1.0)
        case "lightpink":
            self.init(deviceRed: 1.0, green: 0.713725490196078, blue: 0.756862745098039, alpha: 1.0)
        case "lightsalmon":
            self.init(deviceRed: 1.0, green: 0.627450980392157, blue: 0.47843137254902, alpha: 1.0)
        case "lightseagreen":
            self.init(deviceRed: 0.125490196078431, green: 0.698039215686274, blue: 0.666666666666667, alpha: 1.0)
        case "lightskyblue":
            self.init(deviceRed: 0.529411764705882, green: 0.807843137254902, blue: 0.980392156862745, alpha: 1.0)
        case "lightslategray":
            self.init(deviceRed: 0.466666666666667, green: 0.533333333333333, blue: 0.6, alpha: 1.0)
        case "lightsteelblue":
            self.init(deviceRed: 0.690196078431373, green: 0.768627450980392, blue: 0.870588235294118, alpha: 1.0)
        case "lightyellow":
            self.init(deviceRed: 1.0, green: 1.0, blue: 0.87843137254902, alpha: 1.0)
        case "lime":
            self.init(deviceRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case "limegreen":
            self.init(deviceRed: 0.196078431372549, green: 0.803921568627451, blue: 0.196078431372549, alpha: 1.0)
        case "linen":
            self.init(deviceRed: 0.980392156862745, green: 0.941176470588235, blue: 0.901960784313726, alpha: 1.0)
        case "magenta":
            self.init(deviceRed: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
        case "maroon":
            self.init(deviceRed: 0.501960784313725, green: 0.0, blue: 0.0, alpha: 1.0)
        case "mediumaquamarine":
            self.init(deviceRed: 0.4, green: 0.803921568627451, blue: 0.666666666666667, alpha: 1.0)
        case "mediumblue":
            self.init(deviceRed: 0.0, green: 0.0, blue: 0.803921568627451, alpha: 1.0)
        case "mediumorchid":
            self.init(deviceRed: 0.729411764705882, green: 0.333333333333333, blue: 0.827450980392157, alpha: 1.0)
        case "mediumpurple":
            self.init(deviceRed: 0.576470588235294, green: 0.43921568627451, blue: 0.858823529411765, alpha: 1.0)
        case "mediumseagreen":
            self.init(deviceRed: 0.235294117647059, green: 0.701960784313725, blue: 0.443137254901961, alpha: 1.0)
        case "mediumslateblue":
            self.init(deviceRed: 0.482352941176471, green: 0.407843137254902, blue: 0.933333333333333, alpha: 1.0)
        case "mediumspringgreen":
            self.init(deviceRed: 0.0, green: 0.980392156862745, blue: 0.603921568627451, alpha: 1.0)
        case "mediumturquoise":
            self.init(deviceRed: 0.282352941176471, green: 0.819607843137255, blue: 0.8, alpha: 1.0)
        case "mediumvioletred":
            self.init(deviceRed: 0.780392156862745, green: 0.0823529411764706, blue: 0.52156862745098, alpha: 1.0)
        case "midnightblue":
            self.init(deviceRed: 0.0980392156862745, green: 0.0980392156862745, blue: 0.43921568627451, alpha: 1.0)
        case "mintcream":
            self.init(deviceRed: 0.96078431372549, green: 1.0, blue: 0.980392156862745, alpha: 1.0)
        case "mistyrose":
            self.init(deviceRed: 1.0, green: 0.894117647058824, blue: 0.882352941176471, alpha: 1.0)
        case "moccasin":
            self.init(deviceRed: 1.0, green: 0.894117647058824, blue: 0.709803921568627, alpha: 1.0)
        case "navajowhite":
            self.init(deviceRed: 1.0, green: 0.870588235294118, blue: 0.67843137254902, alpha: 1.0)
        case "navy":
            self.init(deviceRed: 0.0, green: 0.0, blue: 0.501960784313725, alpha: 1.0)
        case "oldlace":
            self.init(deviceRed: 0.992156862745098, green: 0.96078431372549, blue: 0.901960784313726, alpha: 1.0)
        case "olive":
            self.init(deviceRed: 0.501960784313725, green: 0.501960784313725, blue: 0.0, alpha: 1.0)
        case "olivedrab":
            self.init(deviceRed: 0.419607843137255, green: 0.556862745098039, blue: 0.137254901960784, alpha: 1.0)
        case "orange":
            self.init(deviceRed: 1.0, green: 0.647058823529412, blue: 0.0, alpha: 1.0)
        case "orangered":
            self.init(deviceRed: 1.0, green: 0.270588235294118, blue: 0.0, alpha: 1.0)
        case "orchid":
            self.init(deviceRed: 0.854901960784314, green: 0.43921568627451, blue: 0.83921568627451, alpha: 1.0)
        case "palegoldenrod":
            self.init(deviceRed: 0.933333333333333, green: 0.909803921568627, blue: 0.666666666666667, alpha: 1.0)
        case "palegreen":
            self.init(deviceRed: 0.596078431372549, green: 0.984313725490196, blue: 0.596078431372549, alpha: 1.0)
        case "paleturquoise":
            self.init(deviceRed: 0.686274509803922, green: 0.933333333333333, blue: 0.933333333333333, alpha: 1.0)
        case "palevioletred":
            self.init(deviceRed: 0.858823529411765, green: 0.43921568627451, blue: 0.576470588235294, alpha: 1.0)
        case "papayawhip":
            self.init(deviceRed: 1.0, green: 0.937254901960784, blue: 0.835294117647059, alpha: 1.0)
        case "peachpuff":
            self.init(deviceRed: 1.0, green: 0.854901960784314, blue: 0.725490196078431, alpha: 1.0)
        case "peru":
            self.init(deviceRed: 0.803921568627451, green: 0.52156862745098, blue: 0.247058823529412, alpha: 1.0)
        case "pink":
            self.init(deviceRed: 1.0, green: 0.752941176470588, blue: 0.796078431372549, alpha: 1.0)
        case "plum":
            self.init(deviceRed: 0.866666666666667, green: 0.627450980392157, blue: 0.866666666666667, alpha: 1.0)
        case "powderblue":
            self.init(deviceRed: 0.690196078431373, green: 0.87843137254902, blue: 0.901960784313726, alpha: 1.0)
        case "purple":
            self.init(deviceRed: 0.501960784313725, green: 0.0, blue: 0.501960784313725, alpha: 1.0)
        case "rebeccapurple":
            self.init(deviceRed: 0.4, green: 0.2, blue: 0.6, alpha: 1.0)
        case "red":
            self.init(deviceRed: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case "rosybrown":
            self.init(deviceRed: 0.737254901960784, green: 0.56078431372549, blue: 0.56078431372549, alpha: 1.0)
        case "royalblue":
            self.init(deviceRed: 0.254901960784314, green: 0.411764705882353, blue: 0.882352941176471, alpha: 1.0)
        case "saddlebrown":
            self.init(deviceRed: 0.545098039215686, green: 0.270588235294118, blue: 0.0745098039215686, alpha: 1.0)
        case "salmon":
            self.init(deviceRed: 0.980392156862745, green: 0.501960784313725, blue: 0.447058823529412, alpha: 1.0)
        case "sandybrown":
            self.init(deviceRed: 0.956862745098039, green: 0.643137254901961, blue: 0.376470588235294, alpha: 1.0)
        case "seagreen":
            self.init(deviceRed: 0.180392156862745, green: 0.545098039215686, blue: 0.341176470588235, alpha: 1.0)
        case "seashell":
            self.init(deviceRed: 1.0, green: 0.96078431372549, blue: 0.933333333333333, alpha: 1.0)
        case "sienna":
            self.init(deviceRed: 0.627450980392157, green: 0.32156862745098, blue: 0.176470588235294, alpha: 1.0)
        case "silver":
            self.init(deviceRed: 0.752941176470588, green: 0.752941176470588, blue: 0.752941176470588, alpha: 1.0)
        case "skyblue":
            self.init(deviceRed: 0.529411764705882, green: 0.807843137254902, blue: 0.92156862745098, alpha: 1.0)
        case "slateblue":
            self.init(deviceRed: 0.415686274509804, green: 0.352941176470588, blue: 0.803921568627451, alpha: 1.0)
        case "slategray":
            self.init(deviceRed: 0.43921568627451, green: 0.501960784313725, blue: 0.564705882352941, alpha: 1.0)
        case "snow":
            self.init(deviceRed: 1.0, green: 0.980392156862745, blue: 0.980392156862745, alpha: 1.0)
        case "springgreen":
            self.init(deviceRed: 0.0, green: 1.0, blue: 0.498039215686275, alpha: 1.0)
        case "steelblue":
            self.init(deviceRed: 0.274509803921569, green: 0.509803921568627, blue: 0.705882352941177, alpha: 1.0)
        case "tan":
            self.init(deviceRed: 0.823529411764706, green: 0.705882352941177, blue: 0.549019607843137, alpha: 1.0)
        case "teal":
            self.init(deviceRed: 0.0, green: 0.501960784313725, blue: 0.501960784313725, alpha: 1.0)
        case "thistle":
            self.init(deviceRed: 0.847058823529412, green: 0.749019607843137, blue: 0.847058823529412, alpha: 1.0)
        case "tomato":
            self.init(deviceRed: 1.0, green: 0.388235294117647, blue: 0.27843137254902, alpha: 1.0)
        case "turquoise":
            self.init(deviceRed: 0.250980392156863, green: 0.87843137254902, blue: 0.815686274509804, alpha: 1.0)
        case "violet":
            self.init(deviceRed: 0.933333333333333, green: 0.509803921568627, blue: 0.933333333333333, alpha: 1.0)
        case "wheat":
            self.init(deviceRed: 0.96078431372549, green: 0.870588235294118, blue: 0.701960784313725, alpha: 1.0)
        case "white":
            self.init(deviceRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case "whitesmoke":
            self.init(deviceRed: 0.96078431372549, green: 0.96078431372549, blue: 0.96078431372549, alpha: 1.0)
        case "yellow":
            self.init(deviceRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case "yellowgreen":
            self.init(deviceRed: 0.603921568627451, green: 0.803921568627451, blue: 0.196078431372549, alpha: 1.0)
        default:
            return nil
        }
    }
}
