 /*
   OSA control code, silent
   - no verbose output
   - all sensor data send to serial port
*/

/*
   naming conventions:
   GLOBAL_CONSTANTS (GLB_CONST)
   global_variables (glb_var)
   methodsAndFunctions
   localConstants (lclConst)
   localvariables (lv)
*/

#include <Wire.h>
#include "src/SGP30/src/SparkFun_SGP30_Arduino_Library.h" // gershow ver
#include "src/ENS210/src/ens210.h"

bool reset_i2c_on_loop = true;

SGP30 os; // create SGP30 object
ENS210 hs; // create ENS210 object

//////////constants&variables//////////

// adjustables
// (shouldn't be able to change via serial command; if want to
// change, modify value here directly and re-upload to each
// teensy; need to modify labview code too)
const int hs_nx = 10; // multiplier for HS data extraction (precision = 1/hs_nx, unit: C)
// below: data codes
const uint8_t CODE_OS_RAW = 1;
const uint8_t CODE_HS = 2;

// teensy-level variables
char cmd_0, cmd_1, cmd_2; // serial command temp variables
uint8_t bus_num; // I2C bus number (useful for 2-teensy setup)
uint8_t f_nx; // multiplier for measurement frequency input
float f_os, f_hs; // OS/HS measurement frequencies; 0 = no measurement

// MUX (multiplexer) variables
// 7-bit MUX address prefix: B1110000 = 0x70
const uint8_t MUX_ADD = 0x70;
// 2-bit OSB address list: B00~B11 = 0x00~0x03
//const uint8_t OSB_ADD[4] = {0x00,0x01,0x02,0x03};
// (unnecessary - hardware decides that OSB address=index, just use 0~3)
// size of osbadd
const uint8_t OSB_N = 4;
bool osb_valid[4]; // OSB valid list (mounted = valid)
bool os_on[4] = {true, true, true, true}; // toggle OSs on/off
bool hs_on[4] = {true, true, true, true}; // toggle HSs on/off

// OS/HS (odor/humidity sensor) variables
const char *CH[16] = {"A0", "A1", "A6", "A7", "B0", "B1", "B6", "B7", "A2", "A3", "A4", "A5", "B2", "B3", "B4", "B5"};
const uint8_t OS_N = 16;
const uint8_t HS_N = 8; // top row only
uint16_t os_ah[16]; // absolute humidity for OS on-chip compensation
int t, t_s, rh, rh_s;
uint16_t hs_partid;
uint64_t hs_uid; // HS helper variables
uint32_t hs_t[8], hs_rh[8]; // HS readings, needed to calculate os_ah
const uint8_t OS_WAIT_TIME = 25; // unit: ms (see SGP30 datasheet)
const uint8_t HS_WAIT_TIME = 130; // unit: ms (see ENS210 datasheet)

// data transmission variables
// 9 data columns:
// ms_timer, code, bus_num, osb_index, sensor_index, sensor_ID, data_1, data_2, valid
uint32_t data_buf[9];
uint8_t DATA_BUF_N = 9;
uint8_t serial_buf[4];


// HARDWARE PINS //

const uint8_t scl0_pin = 19;
const uint8_t sda0_pin = 18;
const uint8_t scl0_stuck_low_pin = 2;
const uint8_t sda0_stuck_low_pin = 3;
const uint8_t scl0_clock_stretch_error_pin = 4;
const uint8_t i2c_reset_indicator_pin = 5;


//////////////////////////
// teensy level methods //
//////////////////////////

void detectOSB() {
  // init helper variables
  uint8_t ma, mb, vn = 0;
  bool mv[2];
  // go through all possible OSB addresses (0x00~0x03)
  for (int i = 0; i < OSB_N; i++) {
    getMuxAddFromOSBAdd(i, ma, mb);
    // do control register echo test on each MUX
    mv[0] = ctrRegEchoTest(ma);
    mv[1] = ctrRegEchoTest(mb);
    // update osb_valid
    if (mv[0] && mv[1]) {
      osb_valid[i] = true;
      vn++;
    } else {
      osb_valid[i] = false;
    }
  }
  // serial response to labview
  if (vn == 0) {
    Serial.write(0);
    return;
  } else {
    Serial.write(1);
  }
  for (int i = 0; i < OSB_N; i++) {
    if (osb_valid[i] == true) {
      Serial.write(i + (bus_num - 1) * 4 + 1);
    }
  }
}

bool testAllOSB() {
  // init helper var
  bool res[OSB_N];
  uint8_t vn, rn;
  vn = 0; rn = 0;
  // test all mounted OSB
  for (int i = 0; i < OSB_N; i++) {
    if (osb_valid[i] == true) {
      vn++; // valid OSB counter
      res[i] = testOSB(i);
      if (res[i] == true) {
        rn++; // good OSB counter
      }
    }
  }
  // if all mounted OSBs are good, return true
  // (also send test result to serial port)
  if (vn == rn) {
    Serial.write(1);
    return true;
  } else {
    Serial.write(0);
    return false;
  }
}

bool resetAllOSB() {
  // init helper var
  bool res[OSB_N];
  uint8_t vn, rn;
  vn = 0; rn = 0;
  // reset all mounted OSB
  for (int i = 0; i < OSB_N; i++) {
    if (osb_valid[i] == true) {
      vn++; // valid OSB counter
      res[i] = resetOSB(i);
      if (res[i] == true) {
        rn++; // good OSB counter
      }
    }
  }
  // if all mounted OSBs are good, return true
  // (also send reset result to serial port)
  if (vn == rn) {
    Serial.write(1);
    return true;
  } else {
    Serial.write(0);
    return false;
  }
}

void i2cReset() {
//resets i2c and displays error messages


  if (reset_i2c_on_loop) {
    digitalWrite(i2c_reset_indicator_pin, HIGH);
    switch (I2C_ClearBus (scl0_pin, sda0_pin)) {
      case 1: digitalWrite(scl0_stuck_low_pin, HIGH); break;
      case 2: digitalWrite(scl0_clock_stretch_error_pin, HIGH); break;
      case 3: digitalWrite(sda0_stuck_low_pin, HIGH); break;
    case 0: default: digitalWrite(scl0_stuck_low_pin, LOW); digitalWrite(sda0_stuck_low_pin, LOW); digitalWrite(scl0_clock_stretch_error_pin, LOW); break;
    }
    Wire.begin();
    digitalWrite(i2c_reset_indicator_pin, LOW);
  }
}

void beginMeasurement() {
  float dt_os, dt_hs;
  if (f_os > 0) {
    dt_os = 1000 / f_os; // odor update time step (ms)
  } else {
    dt_os = 0;
  }
  if (f_hs > 0) {
    dt_hs = 1000 / f_hs; // humidity update time step (ms)
  } else {
    dt_hs = 0;
  }
  long t0_os, t0_hs, t1_os, t1_hs; // clock variables (ms)
  // begin measurement cycles
  t0_os = millis();
  t0_hs = millis();
  while (Serial.available() == 0) {
    i2cReset();
    // A) OS cycle
    t1_os = millis();
    if ((f_os > 0) && (t1_os >= t0_os + dt_os)) {
      t0_os = t1_os;
      // 1) send request: cycle through all mounted OSBs
      for (int i = 0; i < OSB_N; i++) {
        // skip if OSB is not mounted or if OS=off for this OSB
        if ((osb_valid[i] == false) || (os_on[i] == false)) {
          continue;
        }
        requestOS_raw(i);
      }
      // 2) wait for appropriate time
      delay(OS_WAIT_TIME);
      // 3) receive data: cycle through all mounted OSBs
      for (int i = 0; i < OSB_N; i++) {
        // skip if OSB is not mounted or if OS=off for this OSB
        if ((osb_valid[i] == false) ||(os_on[i] == false)) {
          continue;
        }
        readOS_raw(i);
      }
    }
    // B) HS cycle
    t1_hs = millis();
    if ((f_hs > 0) && (t1_hs >= t0_hs + dt_hs)) {
      t0_hs = t1_hs;
      // 1) send request: cycle through all mounted OSBs
      for (int i = 0; i < OSB_N; i++) {
        // skip if OSB is not mounted or if HS=off for this OSB
        if ((osb_valid[i] == false) || (hs_on[i] == false)) {
          continue;
        }
        requestHS(i);
      }
      // 2) wait for appropriate time
      delay(HS_WAIT_TIME);
      // 3) receive data & update AH on OSs: cycle through all mounted OSBs
      for (int i = 0; i < OSB_N; i++) {
        // skip if OSB is not mounted
        if (osb_valid[i] == false) {
          continue;
        }
        // if HS=off, set os_ah to all 0s; otherwise do real measurement
        if (hs_on[i] == false) {
          memset(os_ah, 0, sizeof(os_ah));
        } else {
          readHS(i);
          calcAbsoluteHumidity();
        }
        // if OS=on, send os_ah to OS
        if (os_on[i] == true) {
          setAbsoluteHumidity(i);
        }
      }
      delay(10); // wait time for setAbsoluteHumidity()
    }
  }
}

void minResetOS_allOSB() {
  // only reset OSBs that are mounted and OS=off
  for (int i = 0; i < OSB_N; i++) {
    if ((osb_valid[i] == true) && (os_on[i] == false)) {
      minResetOS(i);
    }
  }
  delay(1); // SGP30 datasheet says <0.6ms soft reset time
}

void minInitOS_allOSB() {
  // send init to OS and request data from HS
  for (int i = 0; i < OSB_N; i++) {
    // skip if OSB is not mounted
    if (osb_valid[i] == false) {
      continue;
    }
    // if OS=on, send init command
    if (os_on[i] == true) {
      minInitOS(i);
    }
    // if HS=on, request data from HS
    if (hs_on[i] == true) {
      requestHS(i);
    }
  }
  // since HS measurement wait time (130ms) > OS init wait
  // time (10ms), use HS wait time only
  delay(HS_WAIT_TIME);
  // update absolute humidity
  for (int i = 0; i < OSB_N; i++) {
    // skip if OSB is not mounted
    if (osb_valid[i] == false) {
      continue;
    }
    // if HS=on, read data from HS
    if (hs_on[i] == true) {
      readHS(i);
      calcAbsoluteHumidity();
    } else {
      memset(os_ah, 0, sizeof(os_ah));
    }
    // if OS=on, send os_ah to OS
    if (os_on[i] == true) {
      setAbsoluteHumidity(i);
    }
  }
  delay(10); // wait time for setAbsoluteHumidity()
}

void minResetHS_allOSB() {
  // only reset OSBs that are mounted and HS=off
  for (int i = 0; i < OSB_N; i++) {
    if ((osb_valid[i] == true) && (hs_on[i] == false)) {
      minResetHS(i);
    }
  }
}

/////////////////
// OSB methods //
/////////////////

bool testOSB(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, return false
  if (osb_valid[osb] == false) {
    return false;
  }
  // OS test cycle
  uint8_t os_n = 0;
  if (os_on[osb] == false) {
    // if OS=off, skip this OSB and set os_n=OS_N, so that test result can still match osb_mounted
    os_n = OS_N;
  } else {
    closeAllChannels(ma, mb);
    for (int i = 0; i < OS_N; i++) {
      openChannel(ma, mb, CH[i]);
      // 1) soft reset
      os.generalCallReset();
      delay(1); // not sure if necessary
      // 2) get serial ID
      if (os.setSerialID() > 0) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 3) run on-chip test
      if (os.measureTest() > 0) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 4) get OS raw signals
      if (os.measureRawSignals() > 0) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 5) if sensor cycle didn't end early, deem success
      os_n++;
      closeAllChannels(ma, mb);
    }
  }
  // HS test cycle
  uint8_t hs_n = 0;
  if (hs_on[osb] == false) {
    // if HS=off, skip this OSB and set hs_n=HS_N, so that test result can still match osb_mounted
    hs_n = HS_N;
  } else {
    closeAllChannels(ma, mb);
    for (int i = 0; i < HS_N; i++) {
      openChannel(ma, mb, CH[i]);
      // 1) soft reset
      if (!hs.reset()) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 2) get serial ID
      if (!hs.getversion(&hs_partid, &hs_uid)) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 3) get HS readings
      t_s = 0; rh_s = 0;
      hs.measure(&t, &t_s, &rh, &rh_s);
      if ((t_s > 1) || (rh_s > 1)) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 4) if sensor cycle didn't end early, deem success
      hs_n++;
      closeAllChannels(ma, mb);
    }
  }
  // if all OS and HS are good, return true
  if ((os_n == OS_N) && (hs_n == HS_N)) {
    return true;
  } else {
    return false;
  }
}

bool resetOSB(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, return false
  if (osb_valid[osb] == false) {
    return false;
  }
  // HS reset cycle
  uint8_t hs_n = 0;
  if (hs_on[osb] == false) {
    // if HS=off, skip this OSB and set hs_n=HS_N, so that reset result can still match osb_mounted
    hs_n = HS_N;
    memset(os_ah, 0, sizeof(os_ah));
  } else {
    closeAllChannels(ma, mb);
    for (int i = 0; i < HS_N; i++) {
      openChannel(ma, mb, CH[i]);
      // 1) soft reset
      if (!hs.reset()) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 2) get serial ID
      if (!hs.getversion(&hs_partid, &hs_uid)) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 3) get HS readings
      t_s = 0; rh_s = 0;
      hs.measure(&t, &t_s, &rh, &rh_s);
      if ((t_s > 1) || (rh_s > 1)) {
        closeAllChannels(ma, mb);
        continue;
      } else {
        hs_t[i] = hs.toCelsius(t, hs_nx);
        hs_rh[i] = hs.toPercentageH(rh, hs_nx);
      }
      // 4) if sensor cycle didn't end early, deem success
      hs_n++;
      closeAllChannels(ma, mb);
    }
    // calculate absolute humidity values
    calcAbsoluteHumidity();
  }
  // OS reset cycle
  uint8_t os_n = 0;
  if (os_on[osb] == false) {
    // if OS=off, skip this OSB and set os_n=OS_N, so that reset result can still match osb_mounted
    os_n = OS_N;
  } else {
    closeAllChannels(ma, mb);
    for (int i = 0; i < OS_N; i++) {
      openChannel(ma, mb, CH[i]);
      // 1) soft reset
      os.generalCallReset();
      delay(1); // not sure if necessary
      // 2) get serial ID
      if (os.setSerialID() > 0) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 3) send init command
      os.initAirQuality();
      delay(10); // max wait time; see SGP30 datasheet
      // 4) update absolute humidity
      os.setHumidity(os_ah[i]);
      delay(10); // max wait time; see SGP30 datasheet
      // 5) get OS raw signals
      if (os.measureRawSignals() > 0) {
        closeAllChannels(ma, mb);
        continue;
      }
      // 5) if sensor cycle didn't end early, deem success
      os_n++;
      closeAllChannels(ma, mb);
    }
  }
  // if all OS and HS are good, return true
  if ((os_n == OS_N) &&(hs_n == HS_N)) {
    return true;
  } else {
    return false;
  }
}

void minResetOS(uint8_t osb) {
  // reset OS only, no re-initializing sensors, no reporting
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // skip if OSB is not mounted
  if (osb_valid[osb] == false) {
    return;
  }
  // OS reset cycle
  closeAllChannels(ma, mb);
  for (int i = 0; i < OS_N; i++) {
    openChannel(ma, mb, CH[i]);
    os.generalCallReset(); // soft reset
    closeAllChannels(ma, mb);
  }
}

void minInitOS(uint8_t osb) {
  // init OS only, no reporting
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // skip if OSB is not mounted
  if (osb_valid[osb] == false) {
    return;
  }
  // OS reset cycle
  closeAllChannels(ma, mb);
  for (int i = 0; i < OS_N; i++) {
    openChannel(ma, mb, CH[i]);
    os.initAirQuality(); // soft reset
    closeAllChannels(ma, mb);
  }
}

void minResetHS(uint8_t osb) {
  // reset HS only, no re-initializing sensors, no reporting
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // skip if OSB is not mounted
  if (osb_valid[osb] == false) {
    return;
  }
  // HS reset cycle
  closeAllChannels(ma, mb);
  for (int i = 0; i < HS_N; i++) {
    openChannel(ma, mb, CH[i]);
    hs.reset(); // 2ms wait time is built in
    closeAllChannels(ma, mb);
  }
}

/////////////////
// MUX methods //
/////////////////

bool ctrRegEchoTest(uint8_t mux) {
  // write 0 to control register
  Wire.beginTransmission(mux);
  Wire.write(0);
  Wire.endTransmission();
  // read from control register
  Wire.requestFrom(mux, (uint8_t) 1);
  if (Wire.read() == 0) {
    return true;
  } else {
    return false;
  }
}

void openChannel(uint8_t mux_a, uint8_t mux_b, const char ch[]) {
  // init helper var
  uint8_t mux;
  uint8_t ctrreg = B00001000;
  // parse channel name
  switch (ch[0]) {
    case 'A': case 'a':
      mux = mux_a;
      break;
    case 'B': case 'b':
      mux = mux_b;
      break;
    default:
      return;
  }
  if ((ch[1] < 48) || (ch[1] > 55)) { // allowed range: '0'~'7'
    return;
  } else {
    uint8_t chnum = (uint8_t)(ch[1] - 48);
    ctrreg = ctrreg + chnum;
  }
  // write to MUX control register
  Wire.beginTransmission(mux);
  Wire.write(ctrreg);
  Wire.endTransmission();
}

void closeAllChannels(uint8_t mux_a, uint8_t mux_b) {
  // close all channels in MA
  Wire.beginTransmission(mux_a);
  Wire.write(B00000000);
  Wire.endTransmission();
  // close all channels in MB
  Wire.beginTransmission(mux_b);
  Wire.write(B00000000);
  Wire.endTransmission();
}

////////////////////////////////////////
// OS/HS (actually OSB level) methods //
////////////////////////////////////////

void setAbsoluteHumidity(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, report error and return
  if (osb_valid[osb] == false) {
    return;
  }
  closeAllChannels(ma, mb);
  for (int i = 0; i < OS_N; i++) {
    openChannel(ma, mb, CH[i]);
    os.setHumidity(os_ah[i]);
    closeAllChannels(ma, mb);
  }
}

void calcAbsoluteHumidity() {
  float t, rh;
  for (int i = 0; i < OS_N; i++) {
    if ((i == 0) || (i == 7)) { // OS_A0/A7: use HS_A0/A7 readings
      t = (float)hs_t[i] / (float)hs_nx;
      rh = (float)hs_t[i] / (float)hs_nx;
    } else if ((i > 0) && (i < 7)) { // top row: nearest neighbor average
      t = ((hs_t[i - 1] + hs_t[i]) / 2.0) / (float)hs_nx;
      rh = ((hs_rh[i - 1] + hs_rh[i]) / 2.0) / (float)hs_nx;
    } else { // bottom row: use HS directly above
      t = (float)hs_t[i - 8] / (float)hs_nx;
      rh = (float)hs_t[i - 8] / (float)hs_nx;
    }
    os_ah[i] = calcAHFromTAndRH(t, rh);
  }
}

uint16_t calcAHFromTAndRH(float t, float rh) {
  // return as 8.8f (in uint16_t as requested by SGP30)
  float dv = exp((17.62 * t) / (243.12 + t));
  dv = (rh / 100) * 6.112 * dv;
  dv = dv / (273.15 + t);
  dv = 216.7 * dv;
  uint16_t DV = (uint8_t)dv;
  DV = DV << 8;
  float dv_dec = dv - (uint8_t)dv;
  DV = DV + (uint8_t)(dv_dec * 256 + 0.5); // +0.5 to round to nearest integer instead of to 0
  return DV;
}

void requestOS_raw(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, report error and return
  if (osb_valid[osb] == false) {
    return;
  }
  closeAllChannels(ma, mb);
  for (int i = 0; i < OS_N; i++) {
    openChannel(ma, mb, CH[i]);
    os.requestRawSignals();
    closeAllChannels(ma, mb);
  }
}

void readOS_raw(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, report error and return
  if (osb_valid[osb] == false) {
    return;
  }
  closeAllChannels(ma, mb);
  for (int i = 0; i < OS_N; i++) {
    memset(data_buf, 0, sizeof(data_buf));
    data_buf[8] = 1; // assume valid first
    openChannel(ma, mb, CH[i]);
    // get code
    data_buf[1] = CODE_OS_RAW;
    // get bus_num
    data_buf[2] = bus_num;
    // get osb_index (bus 1: 1~4; bus 2: 5~8)
    data_buf[3] = osb + (bus_num - 1) * 4 + 1;
    // get sensor_index
    data_buf[4] = i + 1;
    // get measurements
    if (os.readRawSignals() > 0) {
      data_buf[8] = 0; // mark invalid
    } else {
      data_buf[0] = os.readTime;
      data_buf[6] = os.H2;
      data_buf[7] = os.ethanol;
    }
    // get serial ID
    if (os.setSerialID() > 0) {
      data_buf[8] = 0;
    } else {
      data_buf[5] = os.serialID;
    }
    // send to serial port
    sendDataToSerial();
    closeAllChannels(ma, mb);
  }
}

void requestHS(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, report error and return
  if (osb_valid[osb] == false) {
    return;
  }
  closeAllChannels(ma, mb);
  for (int i = 0; i < HS_N; i++) {
    openChannel(ma, mb, CH[i]);
    hs.startsingle();
    closeAllChannels(ma, mb);
  }
}

void readHS(uint8_t osb) {
  // init helper var
  uint8_t ma, mb;
  getMuxAddFromOSBAdd(osb, ma, mb);
  // if OSB is not mounted, report error and return
  if (osb_valid[osb] == false) {
    return;
  }
  // clear temp variables for humidity compensation
  memset(hs_t, 0, sizeof(hs_t));
  memset(hs_rh, 0, sizeof(hs_rh));
  // get HS readings
  closeAllChannels(ma, mb);
  for (int i = 0; i < HS_N; i++) {
    memset(data_buf, 0, sizeof(data_buf));
    data_buf[8] = 1; // assume valid first
    openChannel(ma, mb, CH[i]);
    // get code
    data_buf[1] = CODE_HS;
    // get bus_num
    data_buf[2] = bus_num;
    // get osb_index (bus 1: 1~4; bus 2: 5~8)
    data_buf[3] = osb + (bus_num - 1) * 4 + 1;
    // get sensor_index
    data_buf[4] = i + 1;
    // get measurements
    t_s = 0; rh_s = 0;
    hs.read(&t, &t_s, &rh, &rh_s);
    data_buf[0] = millis();
    if ((t_s > 1) || (rh_s > 1)) {
      data_buf[8] = 0; // mark invalid
    } else {
      hs_t[i] = hs.toCelsius(t, hs_nx);
      data_buf[6] = hs_t[i];
      hs_rh[i] = hs.toPercentageH(rh, hs_nx);
      data_buf[7] = hs_rh[i];
    }
    // get serial ID
    hs_partid = 0; hs_uid = 0;
    if (!hs.getversion(&hs_partid, &hs_uid)) {
      data_buf[8] = 0; // mark invalid
    } else {
      data_buf[5] = hs_uid;
    }
    sendDataToSerial();
    closeAllChannels(ma, mb);
  }
}

/////////////////////
// utility methods //
/////////////////////

void getMuxAddFromOSBAdd(uint8_t osb, uint8_t &mux_a, uint8_t &mux_b) {
  // osb: 2-bit OSB address, ma,mb: 7-bit MUX addresses
  osb = osb << 1;
  mux_a = MUX_ADD + osb;
  mux_b = mux_a + 1;
}

void dispDataInSerialMonitor() {
  for (int j = 0; j < DATA_BUF_N; j++) {
    if (((j == 6) || (j == 7)) && (data_buf[1] == 2)) {
      Serial.print((float)data_buf[j] / (float)hs_nx, log10(hs_nx));
    } else {
      Serial.print(data_buf[j]);
    }
    Serial.print("\t");
  }
  Serial.println();
}

void sendDataToSerial() {
  for (int i = 0; i < DATA_BUF_N; i++) {
    data2byteArr(data_buf[i], serial_buf);
    Serial.write(serial_buf, sizeof(serial_buf));
  }
}

void data2byteArr(uint32_t val, uint8_t valarr[]) {
  for (uint8_t j = 0; j < sizeof(val); j++) {
    valarr[j] = lowByte(val);
    val = val >> 8;
  }
}

/////////////////////////////////////////////////

void setup() {

  pinMode(scl0_stuck_low_pin, OUTPUT);
  pinMode(sda0_stuck_low_pin, OUTPUT);
  pinMode(scl0_clock_stretch_error_pin, OUTPUT);
  pinMode(i2c_reset_indicator_pin, OUTPUT);

  
  // init I2C communication
  Wire.begin();
  Wire.setClock(400000);
  // init serial port
  Serial.begin(9600);
  // init sensor objects
  os.begin();
  hs.begin();
}

void loop() {
  i2cReset();
  if (Serial.available() > 0) {

    // take single char as command
    cmd_0 = (char)Serial.read();
    switch (cmd_0) {
      // A) initialize OSA, detect which OSBs are mounted
      case 'i':
        // get I2C bus number
        if (Serial.available() != 1) {
          /*
            Serial.println("ERROR: unexpected command!");
          */
        } else {
          cmd_1 = (char)Serial.read();
          bus_num = (uint8_t)(cmd_1 - 48);
          // detect OSB mounted on this bus
          /*
            Serial.print("command: initialize bus ");
            Serial.print(bus_num); Serial.println(", detect mounted OSBs");
          */
          detectOSB();
        }
        break;
      // B) run sensor test on one or all OSBs
      case 't':
        cmd_1 = (char)Serial.read();
        switch (cmd_1) {
          case 'a':
            /*
              Serial.println("command: run sensor test on all mounted OSBs");
            */
            testAllOSB();
            break;
          case '0'...'3':
            /*
              Serial.print("command: run sensor test on OSB 0x");
              Serial.println((uint8_t)(cmd_1-48),HEX);
            */
            testOSB((uint8_t)(cmd_1 - 48));
            break;
          default:
            /*
              Serial.println("ERROR: unexpected command!");
            */
            break;
        }
        break;
      // C) reset one or all OSBs
      case 'r':
        cmd_1 = (char)Serial.read();
        switch (cmd_1) {
          case 'a':
            /*
              Serial.println("command: reset all OSBs");
            */
            resetAllOSB();
            break;
          case '0'...'3':
            /*
              Serial.print("command: reset OSB #");
              Serial.println((uint8_t)(cmd_1-48),HEX);
            */
            resetOSB((uint8_t)(cmd_1 - 48));
            break;
          default:
            /*
              Serial.println("ERROR: unexpected command!");
            */
            break;
        }
        break;
      // D) begin measurement
      case 'm':
        if (Serial.available() != 3) {
          /*
            Serial.println("ERROR: unexpected command!");
          */
        } else {
          /*
            Serial.println("command: begin measurement");
          */
          // get multiplier value
          cmd_1 = (uint8_t)Serial.read();
          f_nx = cmd_1;
          // get f_os
          cmd_1 = (uint8_t)Serial.read();
          f_os = (float)cmd_1 / (float)f_nx;
          // get f_hs
          cmd_1 = (uint8_t)Serial.read();
          f_hs = (float)cmd_1 / (float)f_nx;
          // verbose output
          /*
            Serial.print("multiplier = "); Serial.print(f_nx);
            Serial.print("x, f_os = "); Serial.print(f_os,3);
            Serial.print("Hz");
            if(f_os==0) {
            Serial.print(" (no measurement)");
            }
            Serial.print(", f_hs = "); Serial.print(f_hs,3);
            Serial.print("Hz");
            if(f_hs==0) {
            Serial.print(" (no measurement)");
            }
            Serial.println();
          */
          // report starting time for this teensy
          /*
            data_buf[0] = millis();
            data_buf[1] = 0; // set code = 0 so that won't update display
            for(int i=2; i<DATA_BUF_N-1; i++) {
            data_buf[i] = bus_num;
            }
            data_buf[DATA_BUF_N-1] = 0; // mark invalid
            sendDataToSerial();
          */
          // re-init OSs and begin measurement
          minInitOS_allOSB();
          beginMeasurement();
        }
        break;
      // E) toggle OS on/off
      case 'o':
        if (Serial.available() != 2) {
          /*
            Serial.println("ERROR: unexpected command!");
          */
        } else {
          cmd_1 = (char)Serial.read();
          cmd_2 = (char)Serial.read();
          if ((cmd_2 == '0') || (cmd_2 == '1')) {
            switch (cmd_1) {
              case 'a':
                // rewrite os_on
                memset(os_on, (bool)(cmd_2 - 48), sizeof(os_on));
                // verbose output
                /*
                  Serial.print("command: toggle OS ");
                  if(cmd_2=='0') Serial.print("off "); else if(cmd_2=='1') Serial.print("on ");
                  Serial.print("for all OSBs (toggle state: ");
                  for(int i=0; i<OSB_N; i++) {
                  Serial.print((uint8_t)os_on[i]);
                  }
                  Serial.println(")");
                */
                // reset OS to force them into sleep mode
                minResetOS_allOSB();
                break;
              case '0'...'3':
                // rewrite os_on
                os_on[(uint8_t)(cmd_1 - 48)] = (bool)(cmd_2 - 48);
                // verbose output
                /*
                  Serial.print("command: toggle OS ");
                  if(cmd_2=='0') Serial.print("off "); else if(cmd_2=='1') Serial.print("on ");
                  Serial.print("for OSB 0x");
                  Serial.print((uint8_t)(cmd_1-48),HEX);
                  Serial.print("(#");
                  Serial.print((uint8_t)(cmd_1-48)+1,DEC);
                  Serial.print(") (toggle state: ");
                  for(int i=0; i<OSB_N; i++) {
                  Serial.print((uint8_t)os_on[i]);
                  }
                  Serial.println(")");
                */
                // reset OS to force them into sleep mode
                minResetOS((uint8_t)(cmd_1 - 48));
                break;
              default:
                /*
                  Serial.println("ERROR: unexpected command!");
                */
                break;
            }
          } else {
            /*
              Serial.println("ERROR: unexpected command!");
            */
          }
        }
        break;
      // F) toggle HS on/off
      case 'h':
        if (Serial.available() != 2) {
          /*
            Serial.println("ERROR: unexpected command!");
          */
        } else {
          cmd_1 = (char)Serial.read();
          cmd_2 = (char)Serial.read();
          if ((cmd_2 == '0') || (cmd_2 == '1')) {
            switch (cmd_1) {
              case 'a':
                // rewrite hs_on
                memset(hs_on, (bool)(cmd_2 - 48), sizeof(hs_on));
                // verbose output
                /*
                  Serial.print("command: toggle HS ");
                  if(cmd_2=='0') Serial.print("off "); else if(cmd_2=='1') Serial.print("on ");
                  Serial.print("for all OSBs (toggle state: ");
                  for(int i=0; i<OSB_N; i++) {
                  Serial.print((uint8_t)hs_on[i]);
                  }
                  Serial.println(")");
                */
                // reset HS (won't force them into low power mode because of how the ENS210 library is written)
                minResetHS_allOSB();
                break;
              case '0'...'3':
                // rewrite hs_on
                hs_on[(uint8_t)(cmd_1 - 48)] = (bool)(cmd_2 - 48);
                // verbose output
                /*
                  Serial.print("command: toggle HS ");
                  if(cmd_2=='0') Serial.print("off "); else if(cmd_2=='1') Serial.print("on ");
                  Serial.print("for OSB 0x");
                  Serial.print((uint8_t)(cmd_1-48),HEX);
                  Serial.print("(#");
                  Serial.print((uint8_t)(cmd_1-48)+1,DEC);
                  Serial.print(") (toggle state: ");
                  for(int i=0; i<OSB_N; i++) {
                  Serial.print((uint8_t)hs_on[i]);
                  }
                  Serial.println(")");
                */
                // reset HS (won't force them into low power mode because of how the ENS210 library is written)
                minResetHS((uint8_t)(cmd_1 - 48));
                break;
              default:
                /*
                  Serial.println("ERROR: unexpected command!");
                */
                break;
            }
          } else {
            /*
              Serial.println("ERROR: unexpected command!");
            */
          }
        }
        break;
      // Z) unexpected command
      default:
        /*
          Serial.println("ERROR: unexpected command!");
        */
        break;
    }

    // flush serial input buffer
    while (Serial.available() > 0) {
      Serial.read();
    }
  }
}

//adaptation of i2c reset from forward.com.au
/**
   I2C_ClearBus
   (http://www.forward.com.au/pfod/ArduinoProgramming/I2C_ClearBus/index.html)
   (c)2014 Forward Computing and Control Pty. Ltd.
   NSW Australia, www.forward.com.au
   This code may be freely used for both private and commerical use

   adapted 2021, Oct 7 by MHG

*/

/**
   This routine turns off the I2C bus and clears it
   on return SCA and SCL pins are tri-state inputs.
   You need to call Wire.begin() after this to re-enable I2C
   This routine does NOT use the Wire library at all.

   returns 0 if bus cleared
           1 if SCL held low.
           2 if SDA held low by slave clock stretch for > 2sec
           3 if SDA held low after 20 clocks.
*/
int I2C_ClearBus(uint8_t scl_pin, uint8_t sda_pin) {
#if defined(TWCR) && defined(TWEN)
  TWCR &= ~(_BV(TWEN)); //Disable the Atmel 2-Wire interface so we can control the SDA and SCL pins directly
#endif

  pinMode(sda_pin, INPUT_PULLUP); // Make SDA (data) and SCL (clock) pins Inputs with pullup.
  pinMode(scl_pin, INPUT_PULLUP);

  boolean SCL_LOW = (digitalRead(scl_pin) == LOW); // Check is SCL is Low.

  if (SCL_LOW) { //If it is held low Arduno cannot become the I2C master.
    return 1; //I2C bus error. Could not clear SCL clock line held low
  }

  boolean SDA_LOW = (digitalRead(sda_pin) == LOW);  // vi. Check SDA input.

  int clockCount = 20; // > 2x9 clock

  while (SDA_LOW && (clockCount > 0)) { //  vii. If SDA is Low,
    clockCount--;
    // Note: I2C bus is open collector so do NOT drive SCL or SDA high.
    pinMode(scl_pin, INPUT); // release SCL pullup so that when made output it will be LOW
    pinMode(scl_pin, OUTPUT); // then clock SCL Low
    digitalWrite(scl0_pin, LOW); // explicit low write, MHG
    delayMicroseconds(10); //  for >5uS
    pinMode(scl_pin, INPUT); // release SCL LOW
    pinMode(scl_pin, INPUT_PULLUP); // turn on pullup resistors again
    // do not force high as slave may be holding it low for clock stretching.
    delayMicroseconds(10); //  for >5uS
    // The >5uS is so that even the slowest I2C devices are handled.
    SCL_LOW = (digitalRead(scl_pin) == LOW); // Check if SCL is Low.
    int counter = 20;
    while (SCL_LOW && (counter > 0)) {  //  loop waiting for SCL to become High only wait 2sec.
      counter--;
      delay(100);
      SCL_LOW = (digitalRead(scl_pin) == LOW);
    }
    if (SCL_LOW) { // still low after 2 sec error
      return 2; // I2C bus error. Could not clear. SCL clock line held low by slave clock stretch for >2sec
    }
    SDA_LOW = (digitalRead(sda_pin) == LOW); //   and check SDA input again and loop
  }
  if (SDA_LOW) { // still low
    return 3; // I2C bus error. Could not clear. SDA data line held low
  }

  // else pull SDA line low for Start or Repeated Start
  pinMode(sda_pin, INPUT); // remove pullup.
  pinMode(sda_pin, OUTPUT);  // and then make it LOW i.e. send an I2C Start or Repeated start control.
  // When there is only one I2C master a Start or Repeat Start has the same function as a Stop and clears the bus.
  /// A Repeat Start is a Start occurring after a Start with no intervening Stop.
  delayMicroseconds(10); // wait >5uS
  pinMode(sda_pin, INPUT); // remove output low
  pinMode(sda_pin, INPUT_PULLUP); // and make SDA high i.e. send I2C STOP control.
  delayMicroseconds(10); // x. wait >5uS
  pinMode(sda_pin, INPUT); // and reset pins as tri-state inputs which is the default state on reset
  pinMode(scl_pin, INPUT);
  return 0; // all ok
}
