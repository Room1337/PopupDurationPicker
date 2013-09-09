PopupDurationPicker
===================

PopupDurationPicker is a popup view that shows a minutes/seconds picker.

![screenshot](https://raw.github.com/jpmhouston/PopupDurationPicker/master/screenshot%201.png)

This is a mashup of two open source projects I forked, kxmenu & KSAdvancedPicker, plus some custom images
and an orientation feature which I needed for my app.

### Usage

    - (void)showDurationPicker {
        PopupDurationPicker *picker = [[[PopupDurationPicker alloc] initWithTitle:@"Pick Duration" value:5 minSeconds:5 maxMinutes:10];
        picker.target = self;
        picker.action = @selector(durationPicked:);
        [picker showInView:self.view fromRect:sourceRect];
    }
    
    - (void)durationPicked:(id)sender {
        NSLog(@"%d", ((PopupDurationPicker *)sender).value);
    }

See also the demo project.

### Notes

My fork of kxmenu could do with some refactoring instead of the quick & dirty changes I made to allow customization.
For example, I don't like the unnecessary object hierarchy, the public object is a NSObject and the UIView is hidden within it.
Instead I think the object created should be a self-contained UIView subclass itself.
