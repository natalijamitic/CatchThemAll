/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

extension CGPoint {
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  func normalized() -> CGPoint {
    return self / length()
  }
}


struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let pokemon   : UInt32 = 0b1          // 1
  static let pokeball: UInt32 = 0b10           // 2
  static let trainer     : UInt32 = 0b100      // 4
}

class GameScene: SKScene {
  let player = SKSpriteNode(imageNamed: "ash")
  let label = SKLabelNode(fontNamed: "Chalkduster")
  var pokemonsCaught = 0
  var background = SKSpriteNode(imageNamed: "pokemon-background")
  
  override init(size: CGSize) {
    super.init(size: size)
    player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
    player.physicsBody?.isDynamic = true
    player.physicsBody?.categoryBitMask = PhysicsCategory.trainer
    player.physicsBody?.contactTestBitMask = PhysicsCategory.pokemon
    player.physicsBody?.collisionBitMask = PhysicsCategory.none
    
    label.text = "Hit: " + String(pokemonsCaught)
    label.fontSize = 15
    label.fontColor = SKColor.black
    label.position = CGPoint(x: size.width * 0.9 , y: size.height * 0.9)
    addChild(label)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func didMove(to view: SKView) {
    // backgroundColor = SKColor.white
    background.zPosition = -1
    background.position = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    background.size = view.frame.size
    addChild(background)
    
    player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
    addChild(player)
    
    run(SKAction.repeatForever(
      SKAction.sequence([
        SKAction.run(addPokemon),
        SKAction.wait(forDuration: 1.0)
        ])
    ))
    
    physicsWorld.gravity = .zero
    physicsWorld.contactDelegate = self
    
    let backgroundMusic = SKAudioNode(fileNamed: "Sounds/background-music-aac.caf")
    backgroundMusic.autoplayLooped = true
    addChild(backgroundMusic)
  }
  
  func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
  }

  func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
  }

  func addPokemon() {
    let pokemon = SKSpriteNode(imageNamed: "pikachu")
    
    pokemon.physicsBody = SKPhysicsBody(rectangleOf: pokemon.size)
    pokemon.physicsBody?.isDynamic = true
    pokemon.physicsBody?.categoryBitMask = PhysicsCategory.pokemon
    pokemon.physicsBody?.contactTestBitMask = PhysicsCategory.pokeball
    pokemon.physicsBody?.collisionBitMask = PhysicsCategory.none
    
    let actualY = random(min: pokemon.size.height/2, max: size.height - pokemon.size.height/2)
    
    pokemon.position = CGPoint(x: size.width + pokemon.size.width/2, y: actualY)
    
    addChild(pokemon)
    
    let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
    
    let actionMove = SKAction.move(to: CGPoint(x: -pokemon.size.width/2, y: actualY),
                                   duration: TimeInterval(actualDuration))
    let actionMoveDone = SKAction.removeFromParent()
    
    // if pokemon escapes and goes out of screen - GAME LOST
    let loseAction = SKAction.run() { [weak self] in
      guard let `self` = self else { return }
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: false)
      self.view?.presentScene(gameOverScene, transition: reveal)
    }
 //   pokemon.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    pokemon.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    run(SKAction.playSoundFileNamed("Sounds/pew-pew-lei.caf", waitForCompletion: false))
    let touchLocation = touch.location(in: self)
    
    let pokeball = SKSpriteNode(imageNamed: "pokeball")
    pokeball.position = player.position
    
    pokeball.physicsBody = SKPhysicsBody(circleOfRadius: pokeball.size.width/2)
    pokeball.physicsBody?.isDynamic = true
    pokeball.physicsBody?.categoryBitMask = PhysicsCategory.pokeball
    pokeball.physicsBody?.contactTestBitMask = PhysicsCategory.pokemon
    pokeball.physicsBody?.collisionBitMask = PhysicsCategory.none
    pokeball.physicsBody?.usesPreciseCollisionDetection = true
    
    let offset = touchLocation - pokeball.position
    
    // no shooting down or backwards
    if offset.x < 0 { return }
    
    addChild(pokeball)
    
    let direction = offset.normalized()
    
    let shootAmount = direction * 1000
    
    let realDest = shootAmount + pokeball.position
    
    let actionMove = SKAction.move(to: realDest, duration: 2.0)
    let actionMoveDone = SKAction.removeFromParent()
    pokeball.run(SKAction.sequence([actionMove, actionMoveDone]))
  }
  
  
  func pokeballDidCollideWithPokemon(_ pokeball: SKSpriteNode, _ pokemon: SKSpriteNode) {
    print("Hit")
    pokeball.removeFromParent()
    pokemon.removeFromParent()
    pokemonsCaught += 1
    label.text = "Hit: " + String( pokemonsCaught)
    if  pokemonsCaught > 30 {
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      let gameOverScene = GameOverScene(size: self.size, won: true)
      view?.presentScene(gameOverScene, transition: reveal)
    }
  }
  
  func trainerDidCollideWithPokemon(_ trainer: SKSpriteNode, _ pokemon: SKSpriteNode) {
    print("Lost")
    
//    let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
//    let gameOverScene = GameOverScene(size: self.size, won: false)
//    view?.presentScene(gameOverScene, transition: reveal)
  }

}


extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // firstBody is always pokemon
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
   
    // if pokemon caught
    if ((firstBody.categoryBitMask & PhysicsCategory.pokemon != 0) &&
      (secondBody.categoryBitMask & PhysicsCategory.pokeball != 0)) {
      if let pokemon = firstBody.node as? SKSpriteNode,
        let pokeball = secondBody.node as? SKSpriteNode {
        pokeballDidCollideWithPokemon(pokeball, pokemon)
      }
    }
    // if trainer hit by pokemon
    else if ((firstBody.categoryBitMask & PhysicsCategory.pokemon != 0) && (secondBody.categoryBitMask & PhysicsCategory.trainer != 0)) {
      if let pokemon = firstBody.node as? SKSpriteNode,
        let trainer = secondBody.node as? SKSpriteNode {
        trainerDidCollideWithPokemon(trainer, pokemon)
      }
    }
  }
}
