#version 300 es
precision mediump float;

// last reported agent (vertex) position/velocity
in vec4 agent_in;

// texture containing position/velocity of all agents
uniform sampler2D flock;
// total size of flock
uniform float agentCount;
//resolution
uniform vec2 resolution;
//mouse coords
uniform vec2 mouse;

//thresholds, passed from params
uniform float cohesionDist;
uniform float separationDist;
uniform float alignDist;

//scales for different forces
uniform float cohesionScale;
uniform float separationScale;
uniform float alignScale;

//boolean to diffuse boids
uniform bool diffuseBoids;

//Main audio level
uniform float audio;

//Audio scales for each force
uniform float cohesionAudio;
uniform float separationAudio;
uniform float alignAudio;


// newly calculated position / velocity of agent
out vec4 agent_out;

vec2 cohesion = vec2(0., 0.);
vec2 separation = vec2(0., 0.);
vec2 align = vec2(0., 0.);

vec2 acceleration = vec2(0., 0.);
float maxSpeed = .03;
float maxForce = .001;

float random(vec2 coeff) {
  return fract(sin(dot(coeff, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
  // the position of this vertex needs to be reported
  // in the range {-1,1}. We can use the gl_VertexID
  // input variable to determine the current vertex's
  // position in the array and convert it to the desired range.
  float idx = -1. + (float( gl_VertexID ) / agentCount) * 2.;

  // we'll use agent_out to send the agent position and velocity
  // to the fragment shader, which will render it to our 1D texture.
  // agent_out is also the target of our transform feedback.
  agent_out = agent_in;

  if (!diffuseBoids) {
    // loop through all agents...
    for( int i = 0; i < int( agentCount ); i++ ) {
      // make sure the index isn't the index of our current agent
      if( i == gl_VertexID ) continue;

      // get our agent for comparison. texelFetch accepts an integer
      // vector measured in pixels to determine the location of the
      // texture lookup.
      vec4 agent  = texelFetch( flock, ivec2(i,0), 0 );

      float dist = distance(agent_out.xy, agent.xy);

      if (dist < cohesionDist) {
        cohesion += agent.xy;
      }

      if (dist < separationDist) {
        vec2 diff = (agent_out.xy - agent.xy);
        separation += diff;
      }

      if (dist < alignDist) {
        align += agent.zw;
      }
    }

    cohesion = cohesion;
    cohesion -= agent_out.zw;
    if (length(cohesion) > maxForce) {
      cohesion = normalize(cohesion) * maxForce;
    }
    cohesion *= -1.;
    cohesion *= cohesionScale;
    float cohesionTotalAudio;
    if (cohesionAudio > 0.) cohesionTotalAudio = audio * cohesionAudio;
    else cohesionTotalAudio = audio;
    cohesion *= cohesionTotalAudio;

    separation = separation;
    separation -= agent_out.zw;
    if (length(separation) > maxForce) {
      separation = normalize(separation) * maxForce;
    }
    separation *= separationScale;
    float separationTotalAudio;
    if (separationAudio > 0.) separationTotalAudio = audio * separationAudio;
    else separationTotalAudio = audio;
    separation *= separationTotalAudio;

    align -= agent_out.zw;
    if (length(align) > maxForce) {
      align = normalize(align) * maxForce;
    }
    align *= alignScale;
    float alignTotalAudio;
    if (alignAudio > 0.) alignTotalAudio = audio * alignAudio;
    else alignTotalAudio = audio;
    align *= alignTotalAudio;

    acceleration += cohesion + separation + align;
    agent_out.zw += acceleration;
  }

  else {
    agent_out.x = (-1. + (random(agent_out.xy)*2.));
    agent_out.y = (-1. + (random(agent_out.xy)*2.));

  }

  if (length(agent_out.zw) > (maxSpeed)) {
    agent_out.zw = normalize(agent_out.zw);
    agent_out.zw *= (maxSpeed);
  }

  agent_out.x = agent_out.x + agent_out.z;
  agent_out.y = agent_out.y + agent_out.w;

  if (agent_out.x > 1.) agent_out.x = -1.;
  if (agent_out.x < -1.) agent_out.x = 1.;
  if (agent_out.y > 1.) agent_out.y = -1.;
  if (agent_out.y < -1.) agent_out.y = 1.;

  // each agent is one pixel. remember, this shader is not used for
  // rendering to the screen, only to our 1D texture array.
  gl_PointSize = 1.;

  // report our index as the x member of gl_Position. y is always 0.
  gl_Position = vec4( idx, .0, 0., 1. );
}