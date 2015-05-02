class Explosions extends LXPattern {  
  // Used to store info about each wave.
  // See L8onUtil.pde for the definition.
  private List<LEDomeFace> dome_faces;
  private List<L8onExplosion> explosions = new ArrayList<L8onExplosion>();
  private HashMap<Integer, SinLFO> explosionModulators = new HashMap<Integer, SinLFO>(); 

  private final SinLFO saturationModulator = new SinLFO(40.0, 100.0, 20 * SECONDS);

  private BasicParameter numExplosionsParameter = new BasicParameter("NUM", 2.0, 1.0, 30.0);
  private BasicParameter brightnessParameter = new BasicParameter("BRGT", 50, 10, 80);

  private BasicParameter rateParameter = new BasicParameter("RATE", 4000.0, 1.0, 20000.0);
  private BasicParameter delayParameter = new BasicParameter("DELAY", 1000.0, 10.0, 3000.0);
  
  public Explosions(P2LX lx) {
    super(lx);
        
    dome_faces = ((LEDome)model).faces;
    
    addParameter(numExplosionsParameter);
    addParameter(brightnessParameter);
    
    addParameter(rateParameter);    
    addParameter(delayParameter);
    
    addModulator(saturationModulator).start();
    
    initExplosions();
  } 
  
  public void run(double deltaMs) {
    initExplosions();
    
    float base_hue = lx.getBaseHuef();   
    float wave_hue_diff = (float) (360.0 / this.explosions.size());    
    
    for(L8onExplosion explosion : this.explosions) {
      if(explosion.isChillin((float)deltaMs)) {
        continue;
      }
        
      explosion.hue_value = base_hue;
      base_hue += wave_hue_diff;
      
      float dist_to_travel = rateParameter.getValuef() / ((float)deltaMs * 500);
      float dist_to_max_radius = abs(model.xRange - explosion.radius);
      float dist_to_travel_perc = min(dist_to_travel / dist_to_max_radius, 1.0);
      float new_radius = explosion.radius + (dist_to_max_radius * dist_to_travel_perc);
      
      if (explosion.radius >= model.xRange) {
        println("assigning a new center");
        assignNewCenter(explosion);
      } else {
        explosion.setRadius(new_radius);        
      }      
    }  
    
    color c;    
    float hue_value = 0.0;
    float sat_value = saturationModulator.getValuef();
    float brightness_value = brightnessParameter.getValuef();    
    float min_hv;
    float max_hv;
    
    for (LXPoint p : model.points) {
      int num_explosions_in = 0;
     
      for(L8onExplosion explosion : this.explosions) {
        if(explosion.isChillin(0)) {
          continue;
        }
      
        if(explosion.onExplosion(p.x, p.y, p.z)) {
          num_explosions_in++;

          if(num_explosions_in == 1) {
            hue_value = explosion.hue_value;
          } if(num_explosions_in == 2) {
            // Blend new color with previous color.
            min_hv = min(hue_value, explosion.hue_value);
            max_hv = max(hue_value, explosion.hue_value);
            hue_value = (min_hv * 2.0 + max_hv / 2.0) / 2.0;
          } else {
            // Jump color by 180 before blending again.
            hue_value = LXUtils.wrapdistf(0, hue_value + 180, 360);
            min_hv = min(hue_value, explosion.hue_value);
            max_hv = max(hue_value, explosion.hue_value);
            hue_value = (min_hv * 2.0 + max_hv / 2.0) / 2.0;
          }
        }
      }

      if(num_explosions_in > 0) {
        c = lx.hsb(hue_value, sat_value, brightness_value);
      } else {
        c = colors[p.index];                       
        c = lx.hsb(LXColor.h(c), LXColor.s(c), decayed_brightness(deltaMs, c));
      }

      colors[p.index] = c;
    }     
  }
  
  private void initExplosions() {    
    int num_explosions = (int) numExplosionsParameter.getValue();    
    
    if (this.explosions.size() == num_explosions) {
      return;
    }
    
    if (this.explosions.size() < num_explosions) {      
      for(int i = 0; i < (num_explosions - this.explosions.size()); i++) {
        float stroke_width = (6 * INCHES) + random(2 * FEET);
        LEDomeFace dome_face = dome_faces.get((int)random(dome_faces.size()));
        this.explosions.add(
          new L8onExplosion(0, stroke_width, dome_face.he_face.getFaceCenter().xf(), dome_face.he_face.getFaceCenter().yf(), dome_face.he_face.getFaceCenter().zf())
        );
      }  
    } else {
      for(int i = (this.explosions.size() - 1); i >= num_explosions; i--) {
        this.explosions.remove(i);  
      }
    }
  }
  
  private void assignNewCenter(L8onExplosion explosion) {
//    float stroke_width = (6 * INCHES) + random(2 * FEET);
    float stroke_width = 3 * INCHES;
    WB_Point new_center = dome_faces.get((int)random(dome_faces.size())).he_face.getFaceCenter();
    float chill_time = (3.0 + random(7)) * SECONDS;
    
    println("Chill time" + chill_time);
    
    explosion.setCenter(new_center.xf(), new_center.yf(), new_center.zf());
    explosion.setRadius(0, stroke_width);
    explosion.setChillTime(chill_time);
  }
  
  public float decayed_brightness(double deltaMs, color c) {
    float bright_prop = min(((float)deltaMs / delayParameter.getValuef()), 1.0);
    float bright_diff = max((LXColor.b(c) * bright_prop), 1);
    return max(LXColor.b(c) - bright_diff, 0.0);
  }
}

class SpotLights extends LXPattern {
  // Used to store info about each wave.
  // See L8onUtil.pde for the definition.
  private List<L8onSpotLight> spotlights = new ArrayList<L8onSpotLight>();  

  private final SinLFO saturationModulator = new SinLFO(0.0, 100.0, 20 * SECONDS);  
  
  // Controls the radius of the spotlights.
  private BasicParameter radiusParameter = new BasicParameter("RAD", 3 * FEET, 1.0, model.xRange / 2.0);
  private BasicParameter numLightsParameter = new BasicParameter("NUM", 2.0, 1.0, 30.0);
  private BasicParameter brightnessParameter = new BasicParameter("BRGT", 50, 10, 80);  
  
  private BasicParameter rateParameter = new BasicParameter("RATE", 4000.0, 1.0, 10000.0);  
  private BasicParameter restParameter = new BasicParameter("REST", 900.0, 1.0, 10000.0);
  private BasicParameter delayParameter = new BasicParameter("DELAY", 0, 0.0, 2000.0);
  private BasicParameter minDistParameter = new BasicParameter("DIST", 100.0, 10.0, model.xRange);
  
  public SpotLights(P2LX lx) {
    super(lx);        
    
    addParameter(radiusParameter);
    addParameter(numLightsParameter);
    addParameter(brightnessParameter);
    
    addParameter(rateParameter);
    addParameter(restParameter);
    addParameter(delayParameter);
    addParameter(minDistParameter);
    
    addModulator(saturationModulator).start();
        
    initL8onSpotlights();
  }

  public void run(double deltaMs) {
    initL8onSpotlights();
    float spotlight_radius = radiusParameter.getValuef();
    float base_hue = lx.getBaseHuef();   
    float wave_hue_diff = (float) (360.0 / this.spotlights.size());
    float dist_from_dest;
   
    for(L8onSpotLight spotlight : this.spotlights) {
      spotlight.hue_value = base_hue;
      base_hue += wave_hue_diff;
      dist_from_dest = spotlight.distFromDestination();
      
      if (dist_from_dest < 0.01) {
        if(spotlight.time_at_dest_ms > restParameter.getValuef()) {
          // Will set a new destination if first guess is greater than min distance.
          // Otherwise, will keep object as is and try again next tick.
          spotlight.tryNewDestination();
        } else {
          spotlight.addTimeAtDestination((float)deltaMs);  
        }
      } else {        
        float dist_to_travel = rateParameter.getValuef() / ((float)deltaMs * 100);
        float dist_to_travel_perc = min(dist_to_travel / dist_from_dest, 1.0);
        
        spotlight.movePercentageTowardDestination(dist_to_travel_perc);
      }      
    }
   
    color c;    
    float hue_value = 0.0;
    float sat_value = saturationModulator.getValuef();
    float brightness_value = brightnessParameter.getValuef();    
    float min_hv;
    float max_hv;
    
    for (LXPoint p : model.points) {
      int num_spotlights_in = 0;
     
      for(L8onSpotLight spotlight : this.spotlights) {
        float dist_from_spotlight = dist(spotlight.center_x, spotlight.center_y, spotlight.center_z, p.x, p.y, p.z);
        
        if(dist_from_spotlight <= spotlight_radius) {
          num_spotlights_in++;

          if(num_spotlights_in == 1) {
            hue_value = spotlight.hue_value;
          } if(num_spotlights_in == 2) {
            // Blend new color with previous color.
            min_hv = min(hue_value, spotlight.hue_value);
            max_hv = max(hue_value, spotlight.hue_value);
            hue_value = (min_hv * 2.0 + max_hv / 2.0) / 2.0;
          } else {
            // Jump color by 180 before blending again.
            hue_value = LXUtils.wrapdistf(0, hue_value + 180, 360);
            min_hv = min(hue_value, spotlight.hue_value);
            max_hv = max(hue_value, spotlight.hue_value);
            hue_value = (min_hv * 2.0 + max_hv / 2.0) / 2.0;
          }
        }
      }

      if(num_spotlights_in > 0) {
        c = lx.hsb(hue_value, sat_value, brightness_value);
      } else {
        c = colors[p.index];                       
        c = lx.hsb(LXColor.h(c), LXColor.s(c), decayed_brightness(deltaMs, c));
      }

      colors[p.index] = c;
    }     
  }
    
  public float decayed_brightness(double deltaMs, color c) {
    float bright_prop = min(((float)deltaMs / delayParameter.getValuef()), 1.0);
    float bright_diff = max((LXColor.b(c) * bright_prop), 1);
    return max(LXColor.b(c) - bright_diff, 0.0);
  }
  /**
   * Initialize the waves.
   */
  private void initL8onSpotlights() {    
    int num_spotlights = (int) numLightsParameter.getValue();
    if (this.spotlights.size() == num_spotlights) {
      return;
    }
    
    if (this.spotlights.size() < num_spotlights) {
      float min_dist = minDistParameter.getValuef();
      
      for(int i = 0; i < (num_spotlights - this.spotlights.size()); i++) {
        this.spotlights.add(
          new L8onSpotLight(((LEDome)model).sphere,
                            model.xMin + random(model.xRange), model.yMin + random(model.yRange), model.zMin + random(model.zRange), 
                            model.yMin + random(model.yRange), model.yMin + random(model.yRange), model.zMin + random(model.zRange),
                            min_dist)
        );  
      }  
    } else {
      for(int i = (this.spotlights.size() - 1); i >= num_spotlights; i--) {
        this.spotlights.remove(i);  
      }
    }
  }
}


/**
 * 2 slanted breathing waves with bands of color.
 *
 * Each wave is a specific color, their intersection is the mix of those two colors.
 * Between each wave, there are a discrete number of bands of color.
 */
class L8onMixColor extends LXPattern {
  // Oscillators for the wave breathing effect.
  private final SinLFO xOffsetMax = new SinLFO( -1 * (model.xRange / 2.0) , model.xRange / 2.0, 20000);
  private final SinLFO yOffsetMax = new SinLFO( -1 * (model.yRange / 2.0) , model.yRange / 2.0, 20000);
  private final SinLFO zOffsetMax = new SinLFO( -1 * (model.zRange / 2.0) , model.zRange / 2.0, 20000);   
  
  // Used to store info about each wave.
  // See L8onUtil.pde for the definition.
  private List<L8onWave> l8on_waves;
  
  // Controls the radius of the string.
  private BasicParameter radiusParameterX = new BasicParameter("RADX", 1 * FEET, 1.0, model.xRange / 2.0);
  private BasicParameter radiusParameterY = new BasicParameter("RADY", 1 * FEET, 1.0, model.yRange / 2.0);
  private BasicParameter radiusParameterZ = new BasicParameter("RADZ", 1 * FEET, 1.0, model.yRange / 2.0);
  // Controls the center X coordinate of the waves.
  private BasicParameter centerXParameter = new BasicParameter("X", (model.xMin + model.xMax) / 2.0, model.xMin, model.xMax);
    // Controles the center Y coordinate of the waves.
  private BasicParameter centerYParameter = new BasicParameter("Y", (model.yMin + model.yMax) / 2.0, model.yMin, model.yMax);
  // Controls the center Z coordinate of the waves.
  private BasicParameter centerZParameter = new BasicParameter("Z", (model.zMin + model.zMax) / 2.0, model.zMin, model.zMax);
  // Controls the number of waves by axis.
  private BasicParameter numWavesX = new BasicParameter("WAVX", 3.0, 1.0, 10.0);
  private BasicParameter numWavesY = new BasicParameter("WAVY", 4.0, 1.0, 10.0);
  private BasicParameter numWavesZ = new BasicParameter("WAVZ", 4.0, 1.0, 10.0);
  // Controls brightness of on lights
  private BasicParameter brightnessParameter = new BasicParameter("BRGT", 50, 10, 80);
  private BasicParameter saturationParameter = new BasicParameter("SAT", 65, 0, 100);
  // Controls the rate of life algorithm ticks, in milliseconds
  private BasicParameter delayParameter = new BasicParameter("DELAY", 500, 0.0, 2000.0);
  
  public L8onMixColor(P2LX lx) {
    super(lx);
    
    initL8onWaves();

    addParameter(radiusParameterX);
    addParameter(radiusParameterY);
    addParameter(radiusParameterZ);
    addParameter(numWavesX);
    addParameter(numWavesY);
    addParameter(numWavesZ);
    addParameter(centerXParameter);
    addParameter(centerYParameter);
    addParameter(centerZParameter);
    addParameter(brightnessParameter);
    addParameter(saturationParameter);
    addParameter(delayParameter);

    addModulator(xOffsetMax).trigger();
    addModulator(yOffsetMax).trigger();
    addModulator(zOffsetMax).trigger();    
  }
  
  public void run(double deltaMs) {
    float offset_value_x = xOffsetMax.getValuef();
    float offset_value_y = yOffsetMax.getValuef();
    float offset_value_z = zOffsetMax.getValuef();
    float base_hue = lx.getBaseHuef();
    float wave_hue_diff = (float) (360.0 / this.l8on_waves.size());

    for(L8onWave l8on_wave : this.l8on_waves) {
      l8on_wave.hue_value = base_hue;
      base_hue += wave_hue_diff;
    }

    color c;
    float dist_percentage;
    float hue_value = 0.0;
    float sat_value = saturationParameter.getValuef();
    float brightness_value = brightnessParameter.getValuef();
    float wave_center_x;
    float wave_center_y;
    float wave_center_z;
    float wave_radius;
    float min_hv;
    float max_hv;

    for (LXPoint p : model.points) {
      float x_percentage = (p.x - model.xMin) / model.xRange;
      float y_percentage = (p.y - model.yMin) / model.yRange;
      float z_percentage = (p.z - model.zMin) / model.zRange;
      float sin_x = sin(PI / 2 + numWavesX.getValuef() * PI * x_percentage);
      float cos_x = cos(PI / 2 + numWavesX.getValuef() * PI * x_percentage);
      float sin_y = sin(PI / 2 + numWavesY.getValuef() * PI * y_percentage);
      float cos_y = cos(PI / 2 + numWavesY.getValuef() * PI * y_percentage);
      float sin_z = sin(PI / 2 + numWavesZ.getValuef() * PI * z_percentage);
      float cos_z = cos(PI / 2 + numWavesZ.getValuef() * PI * z_percentage);

      int num_waves_in = 0;

      for(L8onWave l8on_wave : this.l8on_waves) {
        wave_center_x = p.x;
        wave_center_y = p.y;
        wave_center_z = p.z;

        if(l8on_wave.direction == L8onWave.DIRECTION_X) {
          wave_center_z = centerZParameter.getValuef() + (l8on_wave.offset_multiplier * offset_value_z * cos_x);
          wave_radius = radiusParameterX.getValuef();          
        } else if(l8on_wave.direction == L8onWave.DIRECTION_Y) {
          wave_center_x = centerXParameter.getValuef() + (l8on_wave.offset_multiplier * offset_value_x * sin_y);
          wave_radius = radiusParameterX.getValuef();          
        } else {
          wave_center_x = centerXParameter.getValuef() + (l8on_wave.offset_multiplier * offset_value_x * sin_z);
          wave_radius = radiusParameterZ.getValuef();
        }

        float dist_from_wave = distance_from_wave(p, wave_center_x, wave_center_y, wave_center_z);

        if(dist_from_wave <= wave_radius) {
          num_waves_in++;

          if(num_waves_in == 1) {
            hue_value = l8on_wave.hue_value;
          } if(num_waves_in == 2) {
            // Blend new color with previous color.
            min_hv = min(hue_value, l8on_wave.hue_value);
            max_hv = max(hue_value, l8on_wave.hue_value);
            hue_value = (min_hv * 2.0 + max_hv / 2.0) / 2.0;
          } else {
            // Jump color by 180 before blending again.
            hue_value = LXUtils.wrapdistf(0, hue_value + 180, 360);
            min_hv = min(hue_value, l8on_wave.hue_value);
            max_hv = max(hue_value, l8on_wave.hue_value);
            hue_value = (min_hv * 2.0 + max_hv / 2.0) / 2.0;
          }
        }
      }

      if(num_waves_in > 0) {
        c = lx.hsb(hue_value, sat_value, brightness_value);
      } else {
        c = colors[p.index];                       
        c = lx.hsb(LXColor.h(c), LXColor.s(c), decayed_brightness(deltaMs, c));
      }

      colors[p.index] = c;
    }
  }
  
  public float decayed_brightness(double deltaMs, color c) {
    float bright_prop = min(((float)deltaMs / delayParameter.getValuef()), 1.0);
    return max(LXColor.b(c) - (LXColor.b(c) * bright_prop), 0.0);
  }
  
  /**
   * Calculates the distance between a point the center of the wave with the given coordinates.
   */
  public float distance_from_wave(LXPoint p, float wave_center_x, float wave_center_y, float wave_center_z) {
    return dist(p.x, p.y, p.z, wave_center_x, wave_center_y, wave_center_z);
  }
  
  /**
   * Initialize the waves.
   */
  private void initL8onWaves() {
    this.l8on_waves = new LinkedList<L8onWave>();

    this.l8on_waves.add( new L8onWave(L8onWave.DIRECTION_X, 1.0) );
    this.l8on_waves.add( new L8onWave(L8onWave.DIRECTION_Y, 1.0) );
    this.l8on_waves.add( new L8onWave(L8onWave.DIRECTION_Z, 1.0) );
    this.l8on_waves.add( new L8onWave(L8onWave.DIRECTION_X, -1.0) );
    this.l8on_waves.add( new L8onWave(L8onWave.DIRECTION_Y, -1.0) );
    this.l8on_waves.add( new L8onWave(L8onWave.DIRECTION_Z, -1.0) );
  }  
}

/**
 * A "Game of Life" simulation in 2 dimensions with the cubes as cells.
 *
 * The "DELAY parameter controls the rate of change.
 * The "MUT" parameter controls the probability of mutations. Useful when life oscillates between few states.
 * The "SAT" parameter controls the saturation.
 *
 * Thanks to Jack for starting me up, Tim for the parameter code, and Slee for the fade idea.
 */
class Life extends LXPattern {
  // Controls the rate of life algorithm ticks, in milliseconds
  private BasicParameter rateParameter = new BasicParameter("DELAY", 700, 0.0, 10 * SECONDS);
  // Controls the probability of a mutation in the cycleOfLife
  private BasicParameter mutationParameter = new BasicParameter("MUT", 0.011, 0.0, 0.1);
  // Controls the saturation.
  private BasicParameter saturationParameter = new BasicParameter("SAT", 75.0, 0.0, 100.0);
  
  private BasicParameter neighborCountParameter = new BasicParameter("NEIG", 0.0, -2.0, 2.0);

  // Alive probability ranges for randomization
  public final double MIN_ALIVE_PROBABILITY = 0.2;
  public final double MAX_ALIVE_PROBABILITY = 0.9;
  
  // The maximum brightness for an alive cell.
  public final float MAX_ALIVE_BRIGHTNESS = 75.0;

  // Cube position oscillator used to select color. 
//  private final SawLFO facePos = new SawLFO(0, ((LEDome)model).getFaces().size(), 4000);
  private final SawLFO facePos = new SawLFO(0, model.yRange, 10 * SECONDS);
  
  // Contains the state of all cubes by index.
  // See L8onUtil.pde for definition of L8onFaceLife.
  private List<L8onFaceLife> face_lives;
  
  private List<LEDomeFace> faces;
  // Contains the amount of time since the last cycle of life.
  private int time_since_last_run;
  // Boolean describing if life changes were made during the current run.
  private boolean any_changes_this_run;
  // Hold the new lives
  private List<Boolean> new_lives;

  public Life(P2LX lx) {
     super(lx);
     this.faces = ((LEDome)model).faces;
     
     //Print debug info about the cubes.
     //outputFaceInfo();

     initFaceStates();
     time_since_last_run = 0;
     any_changes_this_run = false;
     new_lives = new ArrayList<Boolean>(this.faces.size());
     
     addParameter(rateParameter);     
     addParameter(mutationParameter);
     addParameter(saturationParameter);
     addParameter(neighborCountParameter);     

     addModulator(facePos).trigger();
  }
//  
  public void run(double deltaMs) {        
    any_changes_this_run = false;        
    new_lives.clear();
    time_since_last_run += deltaMs;
    
    for (L8onFaceLife face_life : this.face_lives) {
      LEDomeFace face = this.faces.get(face_life.index);
      if (!face.has_lights) {
        continue;
      }

      if(shouldLightFace(face_life)) {
        lightLiveFace(face, face_life, deltaMs);
      } else {
        lightDeadFace(face, face_life, deltaMs);
      } 
    }
    
    // If we have landed in a static state, randomize cubes.
    if(!any_changes_this_run) {
      randomizeFaceStates();  
    } else {
      // Apply new states AFTER ALL new states are decided.
      applyNewLives();
    }
    
    // Reset "tick" timer
    if(time_since_last_run >= rateParameter.getValuef()) {
      time_since_last_run = 0;
    }    
  }
  
  /**
   * Light a live face.
   * Uses deltaMs for fade effect.
   */
  private void lightLiveFace(LEDomeFace face, L8onFaceLife face_life, double deltaMs) {
    float face_dist = LXUtils.wrapdistf(face.yf() - model.yMin, facePos.getValuef(), model.yRange);
    float hv = (face_dist / model.yRange) * 360;
    float bv = face_life.current_brightness;

    // Only change brightness if we are between "ticks" or if there is not enough time to fade.
    if(!face_life.just_changed || deltaMs >= rateParameter.getValuef()) {
      float bright_prop = min(((float) time_since_last_run / rateParameter.getValuef()), 1.0);
      bv = min(MAX_ALIVE_BRIGHTNESS, bright_prop * MAX_ALIVE_BRIGHTNESS);

      if(face_life.current_brightness < bv) {
        face_life.current_brightness = bv;
      } else {
        bv = face_life.current_brightness;
      }
    }
    
    for (LXPoint p : face.points) {      
      colors[p.index] = lx.hsb(
        hv,
        saturationParameter.getValuef(),        
        bv
      );
    }
  }
  
  /**
   * Light a dead face.
   * Uses deltaMs for fade effect.
   */
  private void lightDeadFace(LEDomeFace face, L8onFaceLife face_life, double deltaMs) {    
    float face_dist = LXUtils.wrapdistf(face.yf() - model.yMin, facePos.getValuef(), model.yRange);
    float hv = (face_dist / model.yRange) * 360;
    float bv = face_life.current_brightness;

    // Only change brightness if we are between "ticks" or if there is not enough time to fade.
    if(!face_life.just_changed || deltaMs >= rateParameter.getValuef()) {
      float bright_prop = 1.0 - min(((float) time_since_last_run / rateParameter.getValuef()), 1.0);
      bv = max(0.0, bright_prop * MAX_ALIVE_BRIGHTNESS);

      if(face_life.current_brightness > bv) {
        face_life.current_brightness = bv;
      } else {
        bv = face_life.current_brightness;
      }
    }

    for (LXPoint p : face.points) {
      colors[p.index] = lx.hsb(
        hv,
        saturationParameter.getValuef(),        
        bv
      );     
    }  
  } 
    
  /**
   * Output debug info about the cubes.
   */
  private void outputFaceInfo() {
    int i = 0;      
    for (LEDomeFace face : this.faces) {
      print("LEDomeFace " + i + ": " + face.xf() + "," + face.yf() + "," + face.zf() + "\n");
      ++i;
    }    
  }
  
  /**
   * Initialize the list of face states.
   */
  private void initFaceStates() {   
    boolean alive = false;  
    L8onFaceLife face_life;      
    this.face_lives = new ArrayList<L8onFaceLife>(this.faces.size());
    float current_brightness = 0.0;
    Integer i = 0;     
    
    for (LEDomeFace led_face : this.faces) {      
      alive = false;
      face_life = new L8onFaceLife(i, alive, current_brightness);
      this.face_lives.add(face_life);      
      ++i;
    }
  }
 
 /**
  * Randomizes the state of the cubes.
  * A value between MIN_ALIVE_PROBABILITY and MAX_ALIVE_PROBABILITY is chosen.
  * Each cube then has that probability of living.
  */
  private void randomizeFaceStates() {  
    double prob_range = (1.0 - MIN_ALIVE_PROBABILITY) - (1.0 - MAX_ALIVE_PROBABILITY);
    double prob = MIN_ALIVE_PROBABILITY + (prob_range * Math.random());
    
    println("Randomizing faces p = " + prob);
     
    for (L8onFaceLife face_life : this.face_lives) {   
      face_life.alive = (Math.random() <= prob);            
    }   
  }
  
  /**
   * Will initiate a cycleOfLife if it is time.
   * Otherwise responds based on the current state of the face.
   */
  private boolean shouldLightFace(L8onFaceLife face_life) {
    // Respect rate parameter.
    if(time_since_last_run < rateParameter.getValuef()) {
      any_changes_this_run = true;
      face_life.just_changed = false;
      return face_life.alive;
    } else {
      return cycleOfLife(face_life);
    }
  }

  /**
   * The meat of the life algorithm.
   * Uses the count of live neighbors and the face's current state
   * to decide the face's fate as such:
   * - If alive, needs 2 or 3 living neighbors to stay alive.
   * - If dead, needs 2 living neighbors to be born again.
   *
   * Populates the new_lives array and returns the new state of the cube.
   */
  private boolean cycleOfLife(L8onFaceLife face_life) {
    Integer index = face_life.index;
    Integer alive_neighbor_count = countLiveNeighbors(face_life);               
    boolean before_alive = face_life.alive;
    boolean after_alive = before_alive;
    double mutation = Math.random();
    int neighbor_count_delta = (int) neighborCountParameter.getValuef();       
    
    if (this.faces.get(face_life.index).getNeighbors().size() > 9) {
      neighbor_count_delta++;  
    }

    if(face_life.alive) {
      if(alive_neighbor_count < (2 + neighbor_count_delta) || alive_neighbor_count > (3 +  neighbor_count_delta)) {
        after_alive = false;
      } else {
        after_alive = true;
      }
    } else {
      if(alive_neighbor_count == (3 + neighbor_count_delta)) {
        after_alive = true;
      } else {
        after_alive = false;
      }
    }

    if(mutation <= mutationParameter.getValuef()) {
      after_alive = !after_alive;
    }
    
    if(face_life.index == 51) {
      after_alive = true;  
    }

    if(before_alive != after_alive) {
      face_life.just_changed = true;
      any_changes_this_run = true;
    }

    new_lives.add(after_alive);

    return before_alive;
  }
      
  /**
   * Counts the number of living neighbors of a cube.
   */
  private Integer countLiveNeighbors(L8onFaceLife face_life) {
    Integer count = 0;
    L8onFaceLife neighbor_life;
    
    for(Integer neighbor_index : this.faces.get(face_life.index).getNeighbors()) {
       neighbor_life = this.face_lives.get(neighbor_index);
       if(neighbor_life.alive) {
         count++;
       }
    }   

    return count;
  }

  /**
   * Apply the new states from the new_lives array.
   */
  private void applyNewLives() {
    int index = 0;
    for(boolean liveliness: new_lives) {
      L8onFaceLife face_life = this.face_lives.get(index);
      face_life.alive = new_lives.get(index);
      index++;
    }
  }
}

