import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';

class FootballGame extends FlameGame {
  late final List<Component>
  playerTeam; // Player's team (blue) - can contain both Player and AIPlayer
  late final List<AIPlayer> aiTeam; // AI opponent team (red)
  late final JoystickComponent joystick; // A reference to the joystick
  late final Player controlledPlayer; // The player controlled by joystick
  late final Ball ball;
  late final Goal leftGoal; // Left goal (player defends this)
  late final Goal rightGoal; // Right goal (AI defends this)

  int playerScore = 0;
  int aiScore = 0;

  // The onLoad method is called once when the game is loaded
  @override
  Future<void> onLoad() async {
    // Set up camera to follow the player
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = 0.8; // Zoom out to see the pitch

    // Add the pitch first
    add(Pitch());

    // Create goals - positioned at left/right edges, centered vertically
    // Pitch is 1920 wide, 1080 tall
    // Vertical range: -540 (top) to +540 (bottom), center is y=0
    // Goals should be at y=0 which is exactly midway between top (-540) and bottom (+540)
    const pitchWidth = 1920.0;
    const verticalCenter =
        0.0; // Calculated as: (top + bottom) / 2 = (-540 + 540) / 2 = 0

    leftGoal = Goal(
      position: Vector2(
        -pitchWidth / 2, // Left edge: -960
        verticalCenter, // Vertical center: 0 (midway between -540 and +540)
      ),
      color: Colors.blue.shade300,
      goalWidth: 300,
      goalHeight: 200,
      isLeft: true,
      onScore: () {
        aiScore++;
      },
    );
    rightGoal = Goal(
      position: Vector2(
        pitchWidth / 2, // Right edge: 960
        verticalCenter, // Vertical center: 0 (midway between -540 and +540)
      ),
      color: Colors.red.shade300,
      goalWidth: 300,
      goalHeight: 200,
      isLeft: false,
      onScore: () {
        playerScore++;
      },
    );

    add(leftGoal);
    add(rightGoal);

    // Create the joystick
    joystick = createJoystick();

    // Create ball first (needed for players)
    ball = Ball();

    // Create player team (blue, defending left goal, attacking right goal)
    // Formation: Goalkeeper, then field players in center formation

    // Main player controlled by joystick - center forward (create this first for camera)
    controlledPlayer = Player(
      teamColor: Colors.blue,
      position: Vector2(-200, 0), // Center of left half
      joystick: joystick,
      ball: ball,
      game: this,
    );

    playerTeam = [
      // Goalkeeper - near left goal
      AIPlayer(
        teamColor: Colors.blue,
        position: Vector2(-850, 0), // Near left goal, centered vertically
        ball: ball,
        game: this,
        isGoalkeeper: true,
      ),
      // Main player controlled by joystick
      controlledPlayer,
      // Left midfielder
      AIPlayer(
        teamColor: Colors.blue,
        position: Vector2(-300, -150), // Left side, forward
        ball: ball,
        game: this,
        isGoalkeeper: false,
      ),
      // Right midfielder
      AIPlayer(
        teamColor: Colors.blue,
        position: Vector2(-300, 150), // Right side, forward
        ball: ball,
        game: this,
        isGoalkeeper: false,
      ),
    ];

    // Create AI opponent team (red, defending right goal, attacking left goal)
    // Formation: Goalkeeper, then field players in center formation
    aiTeam = [
      // Goalkeeper - near right goal
      AIPlayer(
        teamColor: Colors.red,
        position: Vector2(850, 0), // Near right goal, centered vertically
        ball: ball,
        game: this,
        isGoalkeeper: true,
      ),
      // Center forward
      AIPlayer(
        teamColor: Colors.red,
        position: Vector2(200, 0), // Center of right half
        ball: ball,
        game: this,
        isGoalkeeper: false,
      ),
      // Left midfielder
      AIPlayer(
        teamColor: Colors.red,
        position: Vector2(300, -150), // Left side, forward
        ball: ball,
        game: this,
        isGoalkeeper: false,
      ),
      // Right midfielder
      AIPlayer(
        teamColor: Colors.red,
        position: Vector2(300, 150), // Right side, forward
        ball: ball,
        game: this,
        isGoalkeeper: false,
      ),
    ];

    // Add ball and all players to game
    add(ball);
    for (var player in playerTeam) {
      add(player);
    }

    // Add AI team players
    for (var aiPlayer in aiTeam) {
      add(aiPlayer);
    }

    // Add joystick last so it's on top
    add(joystick);

    // Set ball's reference to goals for scoring detection
    ball.leftGoal = leftGoal;
    ball.rightGoal = rightGoal;

    return super.onLoad();
  }

  // Update camera to follow the controlled player
  @override
  void update(double dt) {
    super.update(dt);

    // Make camera follow the controlled player, but keep it within pitch bounds
    const pitchWidth = 960.0;
    const pitchHeight = 540.0;

    // Get player position and clamp it to pitch boundaries
    final playerPos = controlledPlayer.position;
    final clampedX = playerPos.x.clamp(-pitchWidth, pitchWidth);
    final clampedY = playerPos.y.clamp(-pitchHeight, pitchHeight);

    // Update camera position to follow player (with boundaries)
    camera.viewfinder.position = Vector2(clampedX, clampedY);
  }

  // Helper method to create our joystick
  JoystickComponent createJoystick() {
    // Style for the joystick's knob
    final knobPaint = Paint()..color = Colors.white.withOpacity(0.5);
    // Style for the joystick's background
    final backgroundPaint = Paint()..color = Colors.grey.withOpacity(0.3);

    return JoystickComponent(
      knob: CircleComponent(radius: 15, paint: knobPaint),
      background: CircleComponent(radius: 40, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
  }
}

// COMPONENT 1: The Pitch
class Pitch extends RectangleComponent {
  Pitch()
    : super(
        size: Vector2(1920, 1080),
        position: Vector2.zero(),
        paint: Paint()..color = Colors.green.shade800,
        anchor: Anchor.center,
      );
}

// COMPONENT 2: Goal
class Goal extends RectangleComponent {
  final bool isLeft;
  final VoidCallback onScore;

  Goal({
    required Vector2 position,
    required Color color,
    required double goalWidth,
    required double goalHeight,
    required this.isLeft,
    required this.onScore,
  }) : super(
         size: Vector2(goalWidth, goalHeight),
         position: position,
         paint: Paint()..color = color.withOpacity(0.7),
         anchor: Anchor.center,
       );

  bool isBallInGoal(Ball ball) {
    final ballPos = ball.position;
    final goalLeft = position.x - size.x / 2;
    final goalRight = position.x + size.x / 2;
    final goalTop = position.y - size.y / 2;
    final goalBottom = position.y + size.y / 2;

    return ballPos.x >= goalLeft &&
        ballPos.x <= goalRight &&
        ballPos.y >= goalTop &&
        ballPos.y <= goalBottom;
  }
}

// COMPONENT 3: A Player
class Player extends CircleComponent with CollisionCallbacks {
  final JoystickComponent? joystick;
  final FootballGame game;
  final double _speed = 200.0; // Player's movement speed (adjusted for zoom)
  final double _kickRange = 30.0; // Distance to kick ball
  final double _kickPower = 300.0; // How hard player kicks
  Ball? ball;

  Player({
    required Color teamColor,
    required this.joystick,
    required this.game,
    Vector2? position,
    this.ball,
  }) : super(
         radius: 20.0,
         position: position ?? Vector2.zero(),
         paint: Paint()..color = teamColor,
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    return super.onLoad();
  }

  // Override the update method to move the player
  @override
  void update(double dt) {
    super.update(dt);

    Vector2 movement = Vector2.zero();

    // If player has joystick, use it
    if (joystick != null && joystick!.direction != JoystickDirection.idle) {
      // Use relativeDelta which is normalized (-1 to 1), then scale by speed
      movement = joystick!.relativeDelta * _speed * dt;
    }

    // Check if player can kick the ball (only if ball exists)
    if (ball != null) {
      final distanceToBall = position.distanceTo(ball!.position);
      if (distanceToBall < _kickRange && joystick != null) {
        // Kick the ball in the direction player is moving
        if (joystick!.direction != JoystickDirection.idle) {
          final kickDirection = joystick!.relativeDelta.normalized();
          ball!.velocity = kickDirection * _kickPower;
        }
      }
    }

    // Move player and keep within pitch bounds
    if (movement.length > 0) {
      final newPosition = position + movement;
      // Keep player within pitch boundaries (accounting for player radius)
      final boundaryMargin = 20.0; // player radius
      if (newPosition.x.abs() < 960 - boundaryMargin &&
          newPosition.y.abs() < 540 - boundaryMargin) {
        position = newPosition;
      }
    }
  }
}

// COMPONENT 4: AI Player
class AIPlayer extends CircleComponent with CollisionCallbacks {
  final Ball ball;
  final FootballGame game;
  final bool isGoalkeeper;
  final double _speed = 180.0; // AI speed (slightly slower than player)
  final double _kickRange = 30.0;
  final double _kickPower = 280.0;
  Vector2 _targetPosition = Vector2.zero();
  double _thinkTimer = 0.0;
  final double _thinkInterval = 0.5; // Update target every 0.5 seconds

  AIPlayer({
    required Color teamColor,
    required Vector2 position,
    required this.ball,
    required this.game,
    this.isGoalkeeper = false,
  }) : super(
         radius: 20.0,
         position: position,
         paint: Paint()..color = teamColor,
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    _targetPosition = position.clone();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _thinkTimer += dt;

    // Update AI thinking periodically
    if (_thinkTimer >= _thinkInterval) {
      _thinkTimer = 0.0;
      _updateTarget();
    }

    // Move towards target
    final direction = (_targetPosition - position);
    if (direction.length > 0.5) {
      final movement = direction.normalized() * _speed * dt;
      final newPosition = position + movement;
      // Keep within pitch bounds (accounting for player radius)
      final boundaryMargin = 20.0; // player radius
      if (newPosition.x.abs() < 960 - boundaryMargin &&
          newPosition.y.abs() < 540 - boundaryMargin) {
        position = newPosition;
      }
    }

    // Check if AI can kick the ball
    final distanceToBall = position.distanceTo(ball.position);
    if (distanceToBall < _kickRange) {
      // Determine kick direction based on team
      final isRedTeam = paint.color == Colors.red;
      final defendingGoalX = isRedTeam ? 850.0 : -850.0;
      final attackingGoalX = isRedTeam ? -960.0 : 960.0;
      final attackingGoal = Vector2(attackingGoalX, 0);

      Vector2 kickDirection;
      if (isGoalkeeper) {
        // Goalkeeper tries to clear the ball away from goal
        final goalPos = Vector2(defendingGoalX, 0);
        kickDirection = (ball.position - goalPos).normalized();
      } else {
        // Other players try to kick towards opponent goal
        kickDirection = (attackingGoal - ball.position).normalized();
      }
      ball.velocity = kickDirection * _kickPower;
    }
  }

  void _updateTarget() {
    // Determine goal position based on team (red team defends right, blue defends left)
    final isRedTeam = paint.color == Colors.red;
    final defendingGoalX = isRedTeam ? 850.0 : -850.0;
    final goalPosition = Vector2(defendingGoalX, 0);

    if (isGoalkeeper) {
      // Goalkeeper stays near goal and moves towards ball if it's close
      final ballDistance = goalPosition.distanceTo(ball.position);
      if (ballDistance < 300) {
        // Move towards ball but stay near goal
        _targetPosition = ball.position * 0.7 + goalPosition * 0.3;
        _targetPosition.x = isRedTeam
            ? _targetPosition.x.clamp(700, 950)
            : _targetPosition.x.clamp(-950, -700);
        _targetPosition.y = _targetPosition.y.clamp(-150, 150);
      } else {
        // Stay in goal position
        _targetPosition = goalPosition;
      }
    } else {
      // Other AI players chase the ball
      final distanceToBall = position.distanceTo(ball.position);
      if (distanceToBall > 50) {
        // Move towards ball
        _targetPosition = ball.position.clone();
        // Add some offset to avoid crowding
        _targetPosition.x += (hashCode % 100 - 50) * 0.1;
        _targetPosition.y += ((hashCode ~/ 100) % 100 - 50) * 0.1;
      } else {
        // If close to ball, position to receive or intercept
        _targetPosition = ball.position.clone();
      }

      // Keep AI players in appropriate half based on team
      if (isRedTeam) {
        // Red team stays in right half, attacks left
        _targetPosition.x = _targetPosition.x.clamp(-950, 600);
      } else {
        // Blue team stays in left half, attacks right
        _targetPosition.x = _targetPosition.x.clamp(-600, 950);
      }
    }
  }
}

// COMPONENT 5: The Ball
class Ball extends CircleComponent with CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  final double _friction = 0.95; // Ball slows down over time
  final double _bounceDamping = 0.7; // Ball bounces but loses energy
  Goal? leftGoal;
  Goal? rightGoal;

  Ball()
    : super(
        radius: 12.0,
        paint: Paint()..color = Colors.white,
        anchor: Anchor.center,
        position: Vector2.zero(), // Start at center of pitch
      );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply velocity
    position += velocity * dt;

    // Apply friction
    velocity *= _friction;
    if (velocity.length < 0.1) {
      velocity = Vector2.zero();
    }

    // Bounce off pitch boundaries
    const pitchWidth = 960.0;
    const pitchHeight = 540.0;

    if (position.x.abs() > pitchWidth) {
      position.x = position.x.sign * pitchWidth;
      velocity.x *= -_bounceDamping;
    }

    if (position.y.abs() > pitchHeight) {
      position.y = position.y.sign * pitchHeight;
      velocity.y *= -_bounceDamping;
    }

    // Check for goals
    if (leftGoal != null && leftGoal!.isBallInGoal(this)) {
      leftGoal!.onScore();
      _resetBall();
    }

    if (rightGoal != null && rightGoal!.isBallInGoal(this)) {
      rightGoal!.onScore();
      _resetBall();
    }
  }

  void _resetBall() {
    position = Vector2.zero();
    velocity = Vector2.zero();
  }
}
