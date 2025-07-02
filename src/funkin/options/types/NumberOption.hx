package funkin.options.types;

import funkin.options.types.BaseOption;

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
        return Std.string(this.value);
    }

	// just realised this would probably allow u to make something with scripts
	// lolll ! !! ! @IamMorwen
	private function _change(next:Float):Void
	{
		var prev:Float = this.value;
		this.value = prev + (this.scrollSpeed * next);
		if (this.value < minimum)
			this.value = maximum;
		if (this.value > maximum)
			this.value = minimum;
		onChange(prev);
	}
}
