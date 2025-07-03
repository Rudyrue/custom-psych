package funkin.options;

import funkin.options.BaseOption;

class NumberOption extends BaseOption<Float, Float>
{
	/**
	 * Minimum (number) value the option can go to before looping back to `maximum`
	**/
	public var minimum:Float = 0.0;

	/**
	 * Maximum (number) value the option can go to before looping back to `minimum`
	**/
	public var maximum:Float = 1.0;

	/**
	 * Scroll Speed in the menus
	**/
	public var scrollSpeed:Float = 1.0;

	/**
	 * Decimals for the number to display
	**/
	public var decimals:Int = 0;

	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	 * @param minimum       Minimum value the option can reach
	 * @param maximum       Maximum value the option can reach
	**/
	public function new(name:String, ?description:String, ?preference:String, ?minimum:Float = 0.0, maximum:Float = 1.0)
	{
		super(name, description, preference);
		this.minimum = minimum;
		this.maximum = maximum;
		this.hasMovement = true;
		this.change = _change;
		this.getText = _getText;
	}

    private function _getText():String {
        return this.valueDisplay.replace('%v', '${this.value}');
    }

	// just realised this would probably allow u to make something with scripts
	// lolll ! !! ! @IamMorwen
	private function _change(next:Float):Void {
		var newValue:Float = FlxMath.roundDecimal(this.value + (this.scrollSpeed * next), decimals);
		this.value = FlxMath.bound(newValue, minimum, maximum);
		onChange(this.value);
	}
}
