# Gauge

[![Version](https://img.shields.io/cocoapods/v/Gauge.svg?style=flat)](https://cocoapods.org/pods/Gauge)
[![License](https://img.shields.io/cocoapods/l/Gauge.svg?style=flat)](https://cocoapods.org/pods/Gauge)
[![Platform](https://img.shields.io/cocoapods/p/Gauge.svg?style=flat)](https://cocoapods.org/pods/Gauge)

![Default Gauge](https://raw.githubusercontent.com/MOLO17/Gauge/master/assets/default-gauge.png)
![Custom Gauge](https://raw.githubusercontent.com/MOLO17/Gauge/master/assets/custom-gauge.png)

`Gauge` is a simple widget to show a value within a range in a circular gauge. It has default
settings, but you can customize the visuals in  many ways and achieve a totally different
result.

`Gauge` is (I hope) well documented with sensible defaults. It has an expressive API and
follows, where it makes sense, protocol oriented programming, so you can easily inject
custom behavior.

## Example

To run the example project, clone the repo, and run `pod install` from the Example
directory first. You can also do `pod try gauge`.

## Usage

Just like any other view, you can create a new instance of it and add it in your view
hierarchy. It can be used in nib files, but it doesn't support `@IBDesignable` and
`@IBInspectable` (I'm sorry, I'm not a fan of Interface Builder. Interested in it? Send a PR).
After that, you can customize it the way you want, changing for example:

* Track color & thickness;
* Gauge offset;
* Empty areas;
* Adding sections to highlight some values;
* Using custom hands;
* Providing custom section labels;
* Providing custom titles;

I won't report here all available options, but I suggest you to check the public API of the
`Gauge` itself.

## TODO

There're still some things missing:
[] Tests;
[] Better POP, for the main labels, min, and max labels;
[] Adding SwiftLint.

## Requirements

## Installation

Gauge is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Gauge'
```

## Author

Alessandro Vendruscolo, alessandro.vendruscolo@gmail.com

## License

Gauge is available under the MIT license. See the LICENSE file for more info.
