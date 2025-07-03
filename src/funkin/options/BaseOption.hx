package funkin.options;

/**
 * Base Class to make option types
 *
 * T is the type of the option
 *
 * VT is the type of value used to change the option
 */
class BaseOption<T:Any, VT:Any> {
	/**
	 * Option Name in the options menu
	**/
	public var name:String = "Unknown";

	/**
	 * Descriptor for what the option does
	**/
	public var description:String = "This option may or may not do something";

	/**
	 * Name of the preference it modifies (in backend.Settings)
	**/
	public var attachedPref:String = null;

	/**
	 * Its (current) value
	**/
	public var value:T = null;

	/**
	 * How the value gets displayed in the options menu
	 * e.g: `%vms` -> 166.67ms
	**/
	public var valueDisplay:String = "%v";

	/**
	 * Used as a sanity-check to see if it can actually be modified
	**/
	public var canChange:Bool = false;

	/**
	 * Contains the original value of the option (used for when pressing R while hovering over it)
	**/
	var defaultValue:T = null;

	/**
	 * If left and right can be used with this option.
	**/
	public var hasMovement:Bool = false;

	/**
	 * If enter can be used with this option.
	**/
	public var hasEnter:Bool = false;

	/**
	 * @param name          Option Name in the options menu
	 * @param description   Descriptor for what the option does
	 * @param preference    Name of the preference it modifies (in backend.Settings)
	**/
	public function new(name:String, ?description:String, ?preference:String) {
		this.name = name;
		this.description = description;
		this.attachedPref = preference;

		getValues();
		canChange = this.defaultValue != null;
	}

	/**
	 * Grab the values from data, typically not overridden.
	**/
	function getValues() {
		defaultValue = Reflect.field(Settings.default_data, attachedPref);
		value = Reflect.field(Settings.data, attachedPref);
	}

	public dynamic function getText():String {
		return "";
	}
	
	public dynamic function enter() {}
	public dynamic function change(value:VT) {}
	public dynamic function onHover() {}
	public dynamic function onChange(previousValue:T) {}

	public inline function getDefaultValue()
		return defaultValue;
}