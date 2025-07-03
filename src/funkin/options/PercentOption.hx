package funkin.options;

import funkin.options.NumberOption;

class PercentOption extends NumberOption {
	// should be in multiples of 10's
	public var multiplyBy:Int = 100;

	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	 * @param minimum       Minimum value the option can reach
	 * @param maximum       Maximum value the option can reach
	**/
	public function new(name:String, ?description:String, ?preference:String, ?minimum:Float = 0.0, maximum:Float = 1.0) {
		super(name, description, preference, minimum, maximum);
	}

    override function _getText():String {
        return this.valueDisplay.replace('%v', '${this.value * multiplyBy}%');
    }
}
