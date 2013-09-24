
object Driver;

object SkipForwardButton;
object SkipBackwardButton;
object SkipBeginButton;
object CasterToggleButton;
object LoadJobButton;
object PinControlWindow;
object JumpToLineWindow;

object JumpToLineButton;

object PinControlItem;
object JumpToLineItem;
object LoadJobItem;

object JumpToLineBox;
object MainWindow;
object PreferenceWindow;

object LinesWebView;

/* Preference controls */
object CycleSensorTypeCheckbox;
object AutoStartStopCheckbox;
object DebounceSlider;

object CurrentLine;
object LineContentsLabel;

object JobName;
object Face;
object Wedge;
object Mould;
object LineLength;

object Thermometer;
object Status;

object CycleIndicator;

object IgnoreCycleButton;
object ManualPinControl;

object cA;
object cB;
object cC;
object cD;
object cE;
object cF;
object cG;
object cH;
object cI;
object cJ;
object cK;
object cL;
object cM;
object cN;

object cS;
object c0005;
object c0075;

object c1;
object c2;
object c3;
object c4;
object c5;
object c6;
object c7;
object c8;
object c9;
object c10;
object c11;
object c12;
object c13;
object c14;

mapping jobinfo;

int CycleSensorMode;
int AutoStartStop;
int was_caster_enabled;

array buttonstotouch = 
	({"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", 
		"S", "0005", "0075"});


static void create()
{
  Driver = ((program)"Driver")(this);
}

//
// Driver interface functions
//

void alert(string title, string body)
{
//  AppKit()->NSRunAlertPanel(title, body, "OK", "", "");
}

void setCycleIndicator(int(0..1) status)
{
//  CycleIndicator->setIntValue_(status);
}

  void setLineContents(string s)
  {
//    LineContentsLabel->setStringValue_(s);
  }

  void setLineStatus(string s)
  {
//    CurrentLine->setStringValue_(s);
  }

  void setStatus(string s)
  {
//    Status->setStringValue_(s);
  }

  void updateThermometer(float percent)
  {
//    Thermometer->setDoubleValue_(percent);
  }

  void toggleCaster(int (0..1) state)
  {
//    CasterToggleButton->setState_(state);
//    toggleCaster_(state);
  }

