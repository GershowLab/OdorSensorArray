/*
 * OSC (odor sensor control) code, silent, HS only
 * - no verbose output
 * - all sensor data send to serial port
 * - OSs and PWR1-4 won't heat up
 */

/*
 * naming conventions:
 * GLOBAL_CONSTANTS (GLB_CONST)
 * global_variables (glb_var)
 * methodsAndFunctions
 * localConstants (lclConst)
 * localvariables (lv)
 */

#include <Wire.h>
#include "src/SparkFun_SGP30_Arduino_Library.h" // gershow ver
#include "src/ens210.h"

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
char cmd_0,cmd_1; // serial command temp variables
uint8_t bus_num; // I2C bus number (useful for 2-teensy setup)
uint8_t f_nx; // multiplier for measurement frequency input
float f_os,f_hs; // OS/HS measurement frequencies; 0 = no measurement

// MUX (multiplexer) variables
// 7-bit MUX address prefix: B1110000 = 0x70
const uint8_t MUX_ADD = 0x70;
// 2-bit OSB address list: B00~B11 = 0x00~0x03
//const uint8_t OSB_ADD[4] = {0x00,0x01,0x02,0x03};
// (unnecessary - hardware decides that OSB address=index, just use 0~3)
// size of osbadd
const uint8_t OSB_N = 4;
// OSB valid list (mounted = valid)
bool osb_valid[4];

// OS/HS (odor/humidity sensor) variables
char *CH[16] = {"A0","A1","A6","A7","B0","B1","B6","B7","A2","A3","A4","A5","B2","B3","B4","B5"};
const uint8_t OS_N = 16;
const uint8_t HS_N = 8; // top row only
uint16_t os_ah[16]; // absolute humidity for OS on-chip compensation
int t,t_s,rh,rh_s;
uint16_t hs_partid;
uint64_t hs_uid; // HS helper variables
uint32_t hs_t[8], hs_rh[8]; // HS readings, needed to calculate os_ah
const uint8_t OS_WAIT_TIME = 25; // unit: ms (see SGP30 datasheet)
const uint8_t HS_WAIT_TIME = 130; // unit: ms (see ENS210 datasheet)

// data transmission variables
uint32_t data_buf[9];
uint8_t DATA_BUF_N = 9;
uint8_t serial_buf[4];

//////////////////////////
// teensy level methods //
//////////////////////////

void detectOSB() {
  // init helper variables
  uint8_t ma,mb,vn;
  bool mv[2];
  // go through all possible OSB addresses (0x00~0x03)
  for(int i=0; i<OSB_N; i++) {
    getMuxAddFromOSBAdd(i,ma,mb);
    /*
    Serial.print("calling OSB 0x"); Serial.print(i,HEX);    
    Serial.print(" (MUX 0x"); Serial.print(ma,HEX);
    Serial.print(", 0x"); Serial.print(mb,HEX); Serial.println(")...");
    */
    // do control register echo test on each MUX
    mv[0] = ctrRegEchoTest(ma);
    mv[1] = ctrRegEchoTest(mb);
    // update osb_valid
    if(mv[0]==true & mv[1]==true) {
      osb_valid[i] = true;
      vn++;
    } else {
      osb_valid[i] = false;
    }
  }
  // verbose output
  /*
  Serial.print("OSB detected:");
  for(int i=0; i<OSB_N; i++) {
    if(osb_valid[i]==true) {
      Serial.print(" "); Serial.print(i+(bus_num-1)*4);
    }
  }
  Serial.println();
  */
  // serial response to labview
  if(vn==0) {
    Serial.write(0);
    return;
  } else {
    Serial.write(1);
  }
  for(int i=0; i<OSB_N; i++) {
    if(osb_valid[i]==true) {
      Serial.write(i+(bus_num-1)*4+1);
    }
  }
}

bool testAllOSB() {
  // init helper var
  bool res[OSB_N];
  uint8_t vn,rn;
  // test all mounted OSB
  for(int i=0; i<OSB_N; i++) {
    if(osb_valid[i]==true) {
      vn++; // valid OSB counter
      res[i] = testOSB(i);
      if(res[i]==true) {
        rn++; // good OSB counter
      }
    }
  }
  // verbose output
  /*
  Serial.print("bus "); Serial.print(bus_num); Serial.print(" test result: ");
  Serial.print(rn); Serial.print("/"); Serial.print(vn); Serial.println(" good OSB");
  */
  // if all mounted OSBs are good, return true
  // (also send test result to serial port)
  if(vn==rn) {
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
  uint8_t vn,rn;
  // reset all mounted OSB
  for(int i=0; i<OSB_N; i++) {
    if(osb_valid[i]==true) {
      vn++; // valid OSB counter
      res[i] = resetOSB(i);
      if(res[i]==true) {
        rn++; // good OSB counter
      }
    }
  }
  // verbose output
  /*
  Serial.print("bus "); Serial.print(bus_num); Serial.print(" reset: ");
  Serial.print(rn); Serial.print("/"); Serial.print(vn); Serial.println(" OSB successfully reset");
  */
  // if all mounted OSBs are good, return true
  // (also send reset result to serial port)
  if(vn==rn) {
    Serial.write(1);
    return true;
  } else {
    Serial.write(0);
    return false;
  }
}

void beginMeasurement() {
  float dt_os, dt_hs;
  /*
  if(f_os>0) {
    dt_os = 1000/f_os; // odor update time step (ms)
  } else {
    dt_os = 0;
  }
  */
  if(f_hs>0) {
    dt_hs = 1000/f_hs; // humidity update time step (ms)
  } else {
    dt_hs = 0;
  }
  long t0_os,t0_hs,t1_os,t1_hs; // clock variables (ms)
  /*
  Serial.println("ms_timer\tcode\tosb_index\tsensor_index\tsensor_ID\tdata_1\tdata_2\tvalid");
  */
  /*
  t0_os = millis();
  */
  t0_hs = millis();
  while(Serial.available()==0) {
    // A) OS cycle
    /*
    t1_os = millis();
    if((f_os>0)&(t1_os>=t0_os+dt_os)) {
      t0_os = t1_os;
      // 1) send request: cycle through all mounted OSBs
      for(int i=0; i<OSB_N; i++) {
        if(osb_valid[i]==false) { // skip if OSB is not mounted
          continue;
        }
        requestOS_raw(i);
      }
      // 2) wait for appropriate time
      delay(OS_WAIT_TIME);
      // 3) receive data: cycle through all mounted OSBs
      for(int i=0; i<OSB_N; i++) {
        if(osb_valid[i]==false) { // skip if OSB is not mounted
          continue;
        }
        readOS_raw(i);
      }
    }
    */
    // B) HS cycle
    t1_hs = millis();
    if((f_hs>0)&(t1_hs>=t0_hs+dt_hs)) {
      t0_hs = t1_hs;
      // 1) send request: cycle through all mounted OSBs
      for(int i=0; i<OSB_N; i++) {
        if(osb_valid[i]==false) { // skip if OSB is not mounted
          continue;
        }
        requestHS(i);
      }
      // 2) wait for appropriate time
      delay(HS_WAIT_TIME);
      // 3) receive data: cycle through all mounted OSBs
      for(int i=0; i<OSB_N; i++) {
        if(osb_valid[i]==false) { // skip if OSB is not mounted
          continue;
        }
        readHS(i);
        // NOTE: if HS post-solder shift is causing problem,
        // can disable on-line humidity compensation in OS by
        // commenting out the following 2 lines
        // HS-only, don't update humidity on OS
        /*
        calcAbsoluteHumidity;
        setAbsoluteHumidity(i);
        */
      }
    }
  }
}

/////////////////
// OSB methods //
/////////////////

bool testOSB(uint8_t osb) {
  // init helper var
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, return false
  if(osb_valid[osb]==false) {
    /*
    Serial.print("OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" test: not mounted");
    */
    return false;
  }
  // OS test cycle
  /*
  uint8_t os_n = 0;
  closeAllChannels(ma,mb);
  for(int i=0; i<OS_N; i++) {
    openChannel(ma,mb,CH[i]);
    // 1) soft reset
    os.generalCallReset();
    delay(1); // not sure if necessary
    // 2) get serial ID
    if(os.setSerialID()>0) {
      continue;
    }
    // 3) run on-chip test
    if(os.measureTest()>0) {
      continue;
    }
    // 4) get OS raw signals
    if(os.measureRawSignals()>0) {
      continue;
    }
    // 5) if sensor cycle didn't end early, deem success
    os_n++;
    closeAllChannels(ma,mb);
  }
  */
  // HS test cycle
  uint8_t hs_n = 0;
  closeAllChannels(ma,mb);
  for(int i=0; i<HS_N; i++) {
    openChannel(ma,mb,CH[i]);
    // 1) soft reset
    if(!hs.reset()) {
      closeAllChannels(ma,mb);
      continue;
    }
    // 2) get serial ID
    if(!hs.getversion(&hs_partid,&hs_uid)) {
      closeAllChannels(ma,mb);
      continue;
    }
    // 3) get HS readings
    t_s = 0; rh_s = 0;
    hs.measure(&t,&t_s,&rh,&rh_s);
    if((t_s>1) | (rh_s>1)) {
      closeAllChannels(ma,mb);
      continue;
    }
    // 4) if sensor cycle didn't end early, deem success
    hs_n++;
    closeAllChannels(ma,mb);
  }
  // verbose output
  /*
  Serial.print("OSB 0x"); Serial.print(osb,HEX); Serial.print(" test: ");
  Serial.print(os_n); Serial.print("/"); Serial.print(OS_N); Serial.print(" good OS, ");
  Serial.print(hs_n); Serial.print("/"); Serial.print(HS_N); Serial.println(" good HS");
  */
  // if all OS and HS are good, return true
  if(hs_n==HS_N) { // HS-only: if all HS are good, return true
  //if((os_n==OS_N)&(hs_n==HS_N)) {
    return true;
  } else {
    return false;
  }
}

bool resetOSB(uint8_t osb) {
  // init helper var
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, return false
  if(osb_valid[osb]==false) {
    /*
    Serial.print("OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" reset: not mounted");
    */
    return false;
  }
  // HS reset cycle
  uint8_t hs_n = 0;
  closeAllChannels(ma,mb);
  for(int i=0; i<HS_N; i++) {
    openChannel(ma,mb,CH[i]);
    // 1) soft reset
    if(!hs.reset()) {
      closeAllChannels(ma,mb);
      continue;
    }
    // 2) get serial ID
    if(!hs.getversion(&hs_partid,&hs_uid)) {
      closeAllChannels(ma,mb);
      continue;
    }
    // 3) get HS readings
    t_s = 0; rh_s = 0;
    hs.measure(&t,&t_s,&rh,&rh_s);
    if((t_s>1) | (rh_s>1)) {
      closeAllChannels(ma,mb);
      continue;
    } else {
      hs_t[i] = hs.toCelsius(t,hs_nx);
      hs_rh[i] = hs.toPercentageH(rh,hs_nx);
    }
    // 4) if sensor cycle didn't end early, deem success
    hs_n++;
    closeAllChannels(ma,mb);
  }
  /*
  // calculate absolute humidity values
  calcAbsoluteHumidity;
  // OS reset cycle
  uint8_t os_n = 0;
  closeAllChannels(ma,mb);
  for(int i=0; i<OS_N; i++) {
    openChannel(ma,mb,CH[i]);
    // 1) soft reset
    os.generalCallReset();
    delay(1); // not sure if necessary
    // 2) get serial ID
    if(os.setSerialID()>0) {
      continue;
    }
    // 3) send init command
    os.initAirQuality();
    delay(10); // max wait time; see SGP30 datasheet
    // 4) update absolute humidity
    os.setHumidity(os_ah[i]);
    delay(10); // max wait time; see SGP30 datasheet
    // 5) get OS raw signals
    if(os.measureRawSignals()>0) {
      continue;
    }
    // 5) if sensor cycle didn't end early, deem success
    os_n++;
    closeAllChannels(ma,mb);
  }
  */
  // verbose output
  /*
  Serial.print("OSB 0x"); Serial.print(osb,HEX); Serial.print(" reset: ");
  Serial.print(os_n); Serial.print("/"); Serial.print(OS_N); Serial.print(" OS, ");
  Serial.print(hs_n); Serial.print("/"); Serial.print(HS_N); Serial.println(" HS successfully reset");
  */
  // if all OS and HS are good, return true
  if(hs_n==HS_N) { // HS-only: if all HS are good, return true
  //if((os_n==OS_N)&(hs_n==HS_N)) { 
    return true;
  } else {
    return false;
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
  Wire.requestFrom(mux,1);
  if(Wire.read()==0) {
    return true;
  } else {
    return false;
  }
}

void openChannel(uint8_t mux_a, uint8_t mux_b, char ch[]) {
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
      /*
      Serial.println("ERROR: unexpected channel name");
      */
      return;
  }
  if ((ch[1]<48)|(ch[1]>55)) { // allowed range: '0'~'7'
    /*
    Serial.println("ERROR: unexpected channel name");
    */
    return;
  } else {
    uint8_t chnum = (uint8_t)(ch[1]-48);
    ctrreg = ctrreg+chnum;
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
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, report error and return
  if(osb_valid[osb]==false) {
    /*
    Serial.print("ERROR: OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" is not mounted");
    */
    return;
  }
  closeAllChannels(ma,mb);
  for(int i=0; i<OS_N; i++) {
    openChannel(ma,mb,CH[i]);
    os.setHumidity(os_ah[i]);
    delay(10); // max wait time; see SGP30 datasheet
    closeAllChannels(ma,mb);
  }
}

void calcAbsoluteHumidity() {
  float t,rh;
  for(int i=0; i<OS_N; i++) {
    if((i==0)|(i==7)) { // OS_A0/A7: use HS_A0/A7 readings
      t = (float)hs_t[i]/(float)hs_nx;
      rh = (float)hs_t[i]/(float)hs_nx;
    } else if((i>0)&(i<7)) { // top row: nearest neighbor average
      t = ((hs_t[i-1]+hs_t[i])/2.0)/(float)hs_nx;
      rh = ((hs_rh[i-1]+hs_rh[i])/2.0)/(float)hs_nx;
    } else { // bottom row: use HS directly above
      t = (float)hs_t[i-8]/(float)hs_nx;
      rh = (float)hs_t[i-8]/(float)hs_nx;
    }
    os_ah[i] = calcAHFromTAndRH(t,rh);
  }
}

uint16_t calcAHFromTAndRH(float t, float rh) {
  // return as 8.8f (in uint16_t as requested by SGP30)
  float dv = exp((17.62*t)/(243.12+t));
  dv = (rh/100)*6.112*dv;
  dv = dv/(273.15+t);
  dv = 216.7*dv;
  uint16_t DV = (uint8_t)dv;
  DV = DV<<8;
  float dv_dec = dv-(uint8_t)dv;
  DV = DV + (uint8_t)(dv_dec*256+0.5); // +0.5 to round to nearest integer instead of to 0
  return DV;
}

void requestOS_raw(uint8_t osb) {
  // init helper var
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, report error and return
  if(osb_valid[osb]==false) {
    /*
    Serial.print("ERROR: OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" is not mounted");
    */
    return;
  }
  closeAllChannels(ma,mb);
  for(int i=0; i<OS_N; i++) {
    openChannel(ma,mb,CH[i]);
    os.requestRawSignals();
    closeAllChannels(ma,mb);
  }
}

void readOS_raw(uint8_t osb) {
  // init helper var
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, report error and return
  if(osb_valid[osb]==false) {
    /*
    Serial.print("ERROR: OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" is not mounted");
    */
    return;
  }
  closeAllChannels(ma,mb);
  for(int i=0; i<OS_N; i++) {
    memset(data_buf,0,sizeof(data_buf));
    data_buf[8] = 1; // assume valid first
    openChannel(ma,mb,CH[i]);
    // get code
    data_buf[1] = CODE_OS_RAW;
    // get bus_num
    data_buf[2] = bus_num;
    // get osb_index (bus 1: 1~4; bus 2: 5~8)
    data_buf[3] = osb+(bus_num-1)*4+1;
    // get sensor_index
    data_buf[4] = i+1;
    // get measurements
    if(os.readRawSignals()>0) {
      data_buf[8] = 0; // mark invalid
    } else {
      data_buf[0] = os.readTime;
      data_buf[6] = os.H2;
      data_buf[7] = os.ethanol;
    }
    // get serial ID
    if(os.setSerialID()>0) {
      data_buf[8] = 0;
    } else {
      data_buf[5] = os.serialID;
    }
    // verbose output
    /*
    dispDataInSerialMonitor();
    */
    // send to serial port
    sendDataToSerial();
    closeAllChannels(ma,mb);
  }
}

void requestHS(uint8_t osb) {
  // init helper var
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, report error and return
  if(osb_valid[osb]==false) {
    /*
    Serial.print("ERROR: OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" is not mounted");
    */
    return;
  }
  closeAllChannels(ma,mb);
  for(int i=0; i<HS_N; i++) {
    openChannel(ma,mb,CH[i]);
    hs.startsingle();
    closeAllChannels(ma,mb);
  }
}

void readHS(uint8_t osb) {
  // init helper var
  uint8_t ma,mb;
  getMuxAddFromOSBAdd(osb,ma,mb);
  // if OSB is not mounted, report error and return
  if(osb_valid[osb]==false) {
    /*
    Serial.print("ERROR: OSB 0x"); Serial.print(osb,HEX);
    Serial.println(" is not mounted");
    */
    return;
  }
  // clear temp variables for humidity compensation
  memset(hs_t,0,sizeof(hs_t));
  memset(hs_rh,0,sizeof(hs_rh));
  // get HS readings
  closeAllChannels(ma,mb);
  for(int i=0; i<HS_N; i++) {
    memset(data_buf,0,sizeof(data_buf));
    data_buf[8] = 1; // assume valid first
    openChannel(ma,mb,CH[i]);
    // get code
    data_buf[1] = CODE_HS;
    // get bus_num
    data_buf[2] = bus_num;
    // get osb_index (bus 1: 1~4; bus 2: 5~8)
    data_buf[3] = osb+(bus_num-1)*4+1;
    // get sensor_index
    data_buf[4] = i+1;
    // get measurements
    t_s = 0; rh_s = 0;
    hs.read(&t,&t_s,&rh,&rh_s);
    data_buf[0] = millis();
    if((t_s>1)|(rh_s>1)) {
      data_buf[8] = 0; // mark invalid
    } else {
      hs_t[i] = hs.toCelsius(t,hs_nx);
      data_buf[6] = hs_t[i];
      hs_rh[i] = hs.toPercentageH(rh,hs_nx);
      data_buf[7] = hs_rh[i];
    }
    // get serial ID
    hs_partid = 0; hs_uid = 0;
    if(!hs.getversion(&hs_partid,&hs_uid)) {
      data_buf[8] = 0; // mark invalid
    } else {
      data_buf[5] = hs_uid;
    }
    // verbose output
    /*
    dispDataInSerialMonitor();
    */
    sendDataToSerial();
    closeAllChannels(ma,mb);
  }
}

/////////////////////
// utility methods //
/////////////////////

void getMuxAddFromOSBAdd(uint8_t osb, uint8_t &mux_a, uint8_t &mux_b) {
  // osb: 2-bit OSB address, ma,mb: 7-bit MUX addresses
  osb = osb<<1;
  mux_a = MUX_ADD+osb;
  mux_b = mux_a+1;
}

void dispDataInSerialMonitor() {
  for(int j=0; j<DATA_BUF_N; j++) {
    if((j==6 | j==7) & data_buf[1]==2) {
      Serial.print((float)data_buf[j]/(float)hs_nx,log10(hs_nx));
    } else {
      Serial.print(data_buf[j]);
    }
    Serial.print("\t");
  }
  Serial.println();
}

void sendDataToSerial() {
  for(int i=0; i<DATA_BUF_N; i++) {
    data2byteArr(data_buf[i],serial_buf);
    Serial.write(serial_buf,sizeof(serial_buf));
  }
}

void data2byteArr(uint32_t val, uint8_t valarr[]) {
  for(int j=0; j<sizeof(val); j++) {
    valarr[j] = lowByte(val);
    val = val>>8;
  }
}

/////////////////////////////////////////////////

void setup() {
  // init I2C communication
  Wire.begin();
  Wire.setClock(100000);
  // init serial port
  Serial.begin(9600);
  // init sensor objects
  os.begin();
  hs.begin();
}

void loop() {
  if(Serial.available()>0) {
    
    // take single char as command
    cmd_0 = (char)Serial.read();
    switch(cmd_0) {
      // A) initialize OSA, detect which OSBs are mounted
      case 'i':
        // get I2C bus number
        // CAUTION: have to remove this if-statement in
        // rui_serialCommunicationTest.ino for it to work with
        // labview (rui_serialCommunicationTest_2teensys.vi),
        // not sure if still a problem in actual code
        if(Serial.available()!=1) {
          /*
          Serial.println("ERROR: unexpected command!");
          */
        } else {
          cmd_1 = (char)Serial.read();
          bus_num = (uint8_t)(cmd_1-48);
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
        switch(cmd_1) {
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
            testOSB((uint8_t)(cmd_1-48));
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
        switch(cmd_1) {
          case 'a':
            /*
            Serial.println("command: reset all OSBs");
            */
            resetAllOSB();
            break;
          case '0'...'6':
            /*
            Serial.print("command: reset OSB #");
            Serial.println((uint8_t)(cmd_1-48),HEX);
            */
            resetOSB((uint8_t)(cmd_1-48));
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
        if(Serial.available()!=3) {
          /*
          Serial.println("ERROR: unexpected command!");
          */
        } else {
          /*
          Serial.println("command: begin measurement");
          */
          // get multiplexer value
          cmd_1 = (uint8_t)Serial.read();
          f_nx = cmd_1;
          // get f_os
          cmd_1 = (uint8_t)Serial.read();
          f_os = (float)cmd_1/(float)f_nx;
          // get f_hs
          cmd_1 = (uint8_t)Serial.read();
          f_hs = (float)cmd_1/(float)f_nx;
          // temp: test if f=0Hz special command works
          // (serial monitor doesn't take char 0 (null))
//          f_nx = 1; f_os = 0.0; f_hs = 0.2;
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
          data_buf[0] = millis();
          data_buf[1] = 0; // set code = 0 so that won't update display
          for(int i=2; i<DATA_BUF_N-1; i++) {
            data_buf[i] = bus_num;
          }
          data_buf[DATA_BUF_N-1] = 0; // mark invalid
          sendDataToSerial();
          // begin measurement
          beginMeasurement();
        }
        break;
      // E) unexpected command
      default:
        /*
        Serial.println("ERROR: unexpected command!");
        */
        break;
    }

    // flush serial input buffer
    while(Serial.available()>0) {
      Serial.read();
    }
  }
}
