/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit

class GameScene: SKScene {

  // MARK: - Instance Variables

  let playerSpeed: CGFloat = 150.0
  let zombieSpeed: CGFloat = 75.0

  var goal: SKSpriteNode?
  var player: SKSpriteNode?
  var zombies: [SKSpriteNode] = []

  var lastTouch: CGPoint? = nil

  override func didMove(to view: SKView) {
    // Set up physics world's contact delegate
    physicsWorld.contactDelegate = self

    // Set up player
    player = childNode(withName: "player") as? SKSpriteNode
    listener = player

    // Set up zombies
    for child in children {
      if child.name == "zombie" {
        if let child = child as? SKSpriteNode {

          // Add SKAudioNode to zombie
          let audioNode = SKAudioNode(fileNamed: "fear_moan.wav")
          child.addChild(audioNode)

          zombies.append(child)
        }
      }
    }
    
    // Set up goal
    goal = childNode(withName: "goal") as? SKSpriteNode
    
    // Set up initial camera position
    updateCamera()
  }

  // MARK: - Touch Handling

  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    handleTouches(touches)
  }

  override func touchesMoved(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    handleTouches(touches)
  }

  override func touchesEnded(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    handleTouches(touches)
  }

  fileprivate func handleTouches(_ touches: Set<UITouch>) {
    lastTouch = touches.first?.location(in: self)
  }

  override func didSimulatePhysics() {
    if player != nil {
      updatePlayer()
      updateZombies()
    }
  }

  // Determines whether the player's position should be updated
  fileprivate func shouldMove(currentPosition: CGPoint,
                              touchPosition: CGPoint) -> Bool {
    guard let player = player else { return false }
    return abs(currentPosition.x - touchPosition.x) > player.frame.width / 2 ||
      abs(currentPosition.y - touchPosition.y) > player.frame.height / 2
  }

  fileprivate func updatePlayer() {
    guard let player = player,
    let touch = lastTouch
      else { return }
    let currentPosition = player.position
    if shouldMove(currentPosition: currentPosition,
                  touchPosition: touch) {
      updatePosition(for: player, to: touch, speed: playerSpeed)
      updateCamera()
    } else {
      player.physicsBody?.isResting = true
    }
  }

  fileprivate func updateCamera() {
    guard let player = player else { return }
    camera?.position = player.position
  }

  // Updates the position of all zombies by moving towards the player
  func updateZombies() {
    guard let player = player else { return }
    let targetPosition = player.position

    for zombie in zombies {
      updatePosition(for: zombie, to: targetPosition, speed: zombieSpeed)
    }
  }

  fileprivate func updatePosition(for sprite: SKSpriteNode,
                                  to target: CGPoint,
                                  speed: CGFloat) {
    let currentPosition = sprite.position
    let angle = CGFloat.pi + atan2(currentPosition.y - target.y,
                                   currentPosition.x - target.x)
    let rotateAction = SKAction.rotate(toAngle: angle + (CGFloat.pi*0.5),
                                       duration: 0)
    sprite.run(rotateAction)

    let velocityX = speed * cos(angle)
    let velocityY = speed * sin(angle)

    let newVelocity = CGVector(dx: velocityX, dy: velocityY)
    sprite.physicsBody?.velocity = newVelocity
  }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // 1. Create local variables for two physics bodies
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody

    // 2. Assign the two physics bodies so that the one with the
    // lower category is always stored in firstBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }

    // 3. react to the contact between the two nodes
    if firstBody.categoryBitMask == player?.physicsBody?.categoryBitMask &&
      secondBody.categoryBitMask == zombies[0].physicsBody?.categoryBitMask {
      // Player & Zombie
      gameOver(false)
    } else if firstBody.categoryBitMask == player?.physicsBody?.categoryBitMask &&
      secondBody.categoryBitMask == goal?.physicsBody?.categoryBitMask {
      // Player & Goal
      gameOver(true)
    }
  }

  // MARK: - Helper Functions

  fileprivate func gameOver(_ didWin: Bool) {
    let menuScene = MenuScene(size: size, didWin: didWin)
    let transition = SKTransition.flipVertical(withDuration: 1.0)
    view?.presentScene(menuScene, transition: transition)
  }
}
