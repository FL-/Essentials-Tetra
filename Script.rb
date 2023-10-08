#===============================================================================
# * Poké Tetra - by FL based in Unknown script (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It's a variation of 
# Triple Triad minigame that is played on a 4x4 board with random neutral
# blocks and with a setting that allows the player to use its party as cards.
#
#===============================================================================
#
# To this script works, put it above main, put a 512x384 background for this
# screen in "Graphics/Pictures/tetrabg" location.
#
# This script called with pbTetraDuel and have the same arguments that
# pbTriadDuel. This script use some of triad classes like TriadSquare. 
#
# You can pass a seventh and eighth parameter as arrays at method 
# call for using color for the player and the opponent. Each array have
# two Color objects, the first is for the border and the second is for inside. 
# There also default color arrays constants at TetraCard class called 
# BLUE, RED, GREEN, PINK, YELLOW, CYAN, PURPLE, ORANGE, BROWN, OLIVE, 
# DARKGREEN, DARKBLUE, WHITE and BLACK. An example call setting the
# player color to DARKBLUE and the opponent to ORANGE:
# 'pbTetraDuel("name",0,4,nil,nil,nil,TetraCard::DARKBLUE,TetraCard::ORANGE)' 
#
# The cards have a +2 point when attacking a type with weakness, -2 for a 
# type with resistance and -4 for a type with immunity. To disable this,
# just use "disabletype" as one of game rules.
#
# If you inform a deck for the opponent bigger that the handsize. The cards
# will be randomly remove until the opponent have the right number of cards.
#
#===============================================================================

class TetraScreen
  # If true, instead of the you select your cards for his deck, 
  # the select pokémon for your current party.
  USEPARTY = true 
  
  # When this number of cards is on the board, the game
  # ends and the result is show.
  PLAYABLECARDS = 10
  
  # The hand size of each player.
  HANDSIZE = 6
end  

class TetraCard
  attr_reader :north, :east, :south, :west, :type, :species
  
  # colorArrays - Border/Inside
  BLUE=[Color.new(64,64,255),Color.new(160,160,255)]
  RED=[Color.new(255,64,64),Color.new(255,160,160)]
  GREEN=[Color.new(64,255,64),Color.new(160,255,160)]
  PINK=[Color.new(255,64,255),Color.new(255,160,255)] # Magenta
  YELLOW=[Color.new(255,255,64),Color.new(255,255,160)]
  CYAN=[Color.new(64,255,255),Color.new(160,255,255)]
  PURPLE=[Color.new(128,32,128),Color.new(128,80,128)]
  ORANGE=[Color.new(255,128,32),Color.new(255,128,80)]
  BROWN=[Color.new(128,32,32),Color.new(128,80,80)]
  OLIVE=[Color.new(128,128,32),Color.new(128,128,80)]
  DARKGREEN=[Color.new(32,128,32),Color.new(80,128,80)]
  DARKBLUE=[Color.new(32,32,128),Color.new(80,80,128)]
  WHITE=[Color.new(224,224,224),Color.new(255,255,255)]
  BLACK=[Color.new(64,64,64),Color.new(160,160,160)]
  
  WIDTH=84
  HEIGHT=84
  
  def baseStatToValue(stat)
    return 9 if stat>=190
    return 8 if stat>=150
    return 7 if stat>=120
    return 6 if stat>=100
    return 5 if stat>=80
    return 4 if stat>=65
    return 3 if stat>=50
    return 2 if stat>=35
    return 1 if stat>=20
    return 0
  end

  def attack(panel)
    return [@west,@east,@north,@south][panel]
  end

  def defense(panel)
    return [@east,@west,@south,@north][panel]
  end

  def bonus(opponent)
    atype=@type
    otype=opponent.type
    mod=PBTypes.getEffectiveness(atype,otype)
    return -4 if mod==0
    return -2 if mod==1
    return 2 if mod==4
    return 0
  end

  def initialize(species)
    dexdata=pbOpenDexData
    @species=species
    pbDexDataOffset(dexdata,species,10)
    hp=baseStatToValue(dexdata.fgetb)
    attack=baseStatToValue(dexdata.fgetb)
    defense=baseStatToValue(dexdata.fgetb)
    speed=baseStatToValue(dexdata.fgetb)
    specialAttack=baseStatToValue(dexdata.fgetb)
    specialDefense=baseStatToValue(dexdata.fgetb)
    @west=(attack>specialAttack) ? attack : specialAttack # Picks the bigger
    @east=(defense>specialDefense) ? defense : specialDefense # Picks the bigger
    @north=hp
    @south=speed
    pbDexDataOffset(dexdata,species,8)
    @type=dexdata.fgetb # Type
    if isConst?(@type,PBTypes,:NORMAL)
      type2=dexdata.fgetb
      @type=type2 if !isConst?(type2,PBTypes,:NORMAL)
    end
    dexdata.close
  end

  def self.createBack(type=-1,colorArray=nil)
    bitmap=BitmapWrapper.new(TetraCard::WIDTH,TetraCard::HEIGHT)
    TetraCard.fillColor(bitmap,colorArray) if colorArray # noback==false
    if type>=0
      typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
      typerect=Rect.new(0,type*28,64,28)
      bitmap.blt((TetraCard::WIDTH-64)/2,(TetraCard::HEIGHT-28)/2,
          typebitmap.bitmap,typerect,192)
      typebitmap.dispose
    end
    return bitmap
  end

  def createBitmap(owner,colorArray)
    if owner==0
      return TetraCard.createBack(-1,colorArray)
    end
    bitmap=BitmapWrapper.new(TetraCard::WIDTH,TetraCard::HEIGHT)
    iconfile=pbCheckPokemonIconFiles([@species,0,false,0,false])
    typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    icon=AnimatedBitmap.new(iconfile)
    typerect=Rect.new(0,@type*28,64,28)
    TetraCard.fillColor(bitmap,colorArray)
    bitmap.blt((TetraCard::WIDTH-64)/2,(TetraCard::HEIGHT-28)/2,
        typebitmap.bitmap,typerect,192)
    bitmap.blt(10,2,icon.bitmap,Rect.new(0,0,64,64))
    pbSetSmallFont(bitmap)
    pbDrawTextPositions(bitmap,[
       ["0123456789A"[@north,1],TetraCard::HEIGHT/2,2,2,
           Color.new(248,248,248),Color.new(96,96,96)],
       ["0123456789A"[@south,1],TetraCard::HEIGHT/2,(TetraCard::HEIGHT-2)-24,2,
           Color.new(248,248,248),Color.new(96,96,96)],
       ["0123456789A"[@west,1],2,(TetraCard::WIDTH/2)-12,0,
           Color.new(248,248,248),Color.new(96,96,96)],
       ["0123456789A"[@east,1],TetraCard::WIDTH-2,(TetraCard::WIDTH/2)-12,1,
           Color.new(248,248,248),Color.new(96,96,96)]
    ])
    icon.dispose
    typebitmap.dispose
    return bitmap
  end
  
  def self.createBlockBitmap
    bitmap=BitmapWrapper.new(TetraCard::WIDTH,TetraCard::HEIGHT)
    cardColor = Color.new(29,107,64)
    TetraCard.fillColor(bitmap,[cardColor,cardColor])
    return bitmap
  end  
  
  def self.fillColor(bitmap,colorArray)
    bitmap.fill_rect(0,0,TetraCard::WIDTH,TetraCard::HEIGHT,colorArray[0])
    bitmap.fill_rect(2,2,TetraCard::WIDTH-4,TetraCard::HEIGHT-4,colorArray[1])
  end  
end

# Scene class for handling appearance of the screen
class TetraScene
  
  # Initialize the colors and the default values
  def initialize(colorArrayPlayer, colorArrayOpponent)
    @colorArrayPlayer = colorArrayPlayer
    @colorArrayOpponent = colorArrayOpponent
    if !@colorArrayPlayer || (@colorArrayPlayer==@colorArrayOpponent && 
        @colorArrayPlayer==TetraCard::RED)
      @colorArrayPlayer = TetraCard::BLUE 
    end
    if !@colorArrayOpponent || (@colorArrayPlayer==@colorArrayOpponent && 
        @colorArrayPlayer==TetraCard::BLUE)
      @colorArrayOpponent = TetraCard::RED 
    end
  end  
  
# Update the scene here, this is called once each frame
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

# End the scene here
  def pbEndScene
    pbBGMFade(1.0)
    # Fade out all sprites
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Dispose all sprites
    pbDisposeSpriteHash(@sprites)
    @bitmaps.each{|bm| bm.dispose }
    # Dispose the viewport
    @viewport.dispose
  end

  FIELDBASEX = 88
  FIELDBASEY = 46
  HANDBASEY = 34
  HANDBONUSY = 48
  PLAYERHANDBASEX = Graphics.width-TetraCard::WIDTH-2
  OPPONENTHANDBASEX = 2
  
  def pbStartScene(battle)
    # Create sprite hash
    @sprites={}
    @bitmaps=[]
    @battle=battle
    # Allocate viewport
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    addBackgroundPlane(@sprites,"background","tetrabg",@viewport)
    @sprites["helpwindow"]=Window_AdvancedTextPokemon.newWithSize("",
       0,Graphics.height-64,Graphics.width,64,@viewport)
    for i in 0...@battle.width*@battle.height
      @sprites["sprite#{i}"]=SpriteWrapper.new(@viewport)
      cardX=FIELDBASEX + (i%@battle.width)*TetraCard::WIDTH
      cardY=FIELDBASEY + (i/@battle.width)*TetraCard::HEIGHT
      @sprites["sprite#{i}"].z=2
      @sprites["sprite#{i}"].x=cardX
      @sprites["sprite#{i}"].y=cardY
      bm=TetraCard.createBack(@battle.board[i].type)
      @bitmaps.push(bm)
      @sprites["sprite#{i}"].bitmap=bm
    end
    @cardBitmaps=[]
    @opponentCardBitmaps=[]
    @cardIndexes=[]
    @opponentCardIndexes=[]
    @boardSprites=[]
    @boardCards=[]
    for i in 0...TetraScreen::HANDSIZE
      @sprites["player#{i}"]=Sprite.new(@viewport)
      @sprites["player#{i}"].z=2
      @sprites["player#{i}"].x=PLAYERHANDBASEX
      @sprites["player#{i}"].y=HANDBASEY+6+16*i
      @cardIndexes.push(i)
    end
    @sprites["overlay"]=Sprite.new(@viewport)
    @sprites["overlay"].bitmap=BitmapWrapper.new(Graphics.width,Graphics.height)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap,[
       [@battle.opponentName,54,0,2,
           Color.new(248,248,248),Color.new(96,96,96)],
       [@battle.playerName,Graphics.width-54,0,2,
           Color.new(248,248,248),Color.new(96,96,96)]
    ])
    @sprites["score"]=Sprite.new(@viewport)
    @sprites["score"].bitmap=BitmapWrapper.new(Graphics.width,Graphics.height)
    pbSetSystemFont(@sprites["score"].bitmap)
    pbBGMPlay("021-Field04")
    # Fade in all sprites
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbUpdateScore
    bitmap=@sprites["score"].bitmap
    bitmap.clear
    playerscore=0
    oppscore=0
    for i in 0...@battle.width*@battle.height
      if @boardSprites[i]
        playerscore+=1 if @battle.board[i].owner==1
        oppscore+=1 if @battle.board[i].owner==2
      end
    end
    if @battle.countUnplayedCards
      playerscore+=@cardIndexes.length
      oppscore+=@opponentCardIndexes.length
    end
    pbDrawTextPositions(bitmap,[
       [_INTL("{1}-{2}",oppscore,playerscore),Graphics.width/2,0,2,
           Color.new(248,248,248),Color.new(96,96,96)]
    ])
  end

  def pbNotifyCards(playerCards,opponentCards)
    @playerCards=playerCards
    @opponentCards=opponentCards
  end

  def pbDisplay(text)
    @sprites["helpwindow"].visible=true
    @sprites["helpwindow"].text=text
    60.times do
      Graphics.update
      Input.update
      pbUpdate
    end
  end

  def pbDisplayPaused(text)
    @sprites["helpwindow"].letterbyletter=true
    @sprites["helpwindow"].text=text+"\1"
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::C)
        if @sprites["helpwindow"].busy?
          pbPlayDecisionSE() if @sprites["helpwindow"].pausing?
          @sprites["helpwindow"].resume
        else
          break
        end
      end
    end
    @sprites["helpwindow"].letterbyletter=false
    @sprites["helpwindow"].text=""
  end
  
  def pbWindowVisible(visible)
    @sprites["helpwindow"].visible=visible
  end  

  def pbShowPlayerCards(cards)
    for i in 0...TetraScreen::HANDSIZE
      @sprites["player#{i}"]=Sprite.new(@viewport)
      @sprites["player#{i}"].z=2
      @sprites["player#{i}"].x=PLAYERHANDBASEX
      @sprites["player#{i}"].y=HANDBASEY+HANDBONUSY*i
      @sprites["player#{i}"].bitmap=TetraCard.new(cards[i]).createBitmap(
          1,colorArrayPlayer)
      @cardBitmaps.push(@sprites["player#{i}"].bitmap)
    end
  end

  def pbShowOpponentCards(cards)
    for i in 0...TetraScreen::HANDSIZE
      @sprites["opponent#{i}"]=Sprite.new(@viewport)
      @sprites["opponent#{i}"].z=2
      @sprites["opponent#{i}"].x=OPPONENTHANDBASEX
      @sprites["opponent#{i}"].y=HANDBASEY+HANDBONUSY*i
      @sprites["opponent#{i}"].bitmap=@battle.openHand ? 
          TetraCard.new(cards[i]).createBitmap(2,@colorArrayOpponent) : 
          TetraCard.createBack(-1,@colorArrayOpponent)
      @opponentCardBitmaps.push(@sprites["opponent#{i}"].bitmap)
      @opponentCardIndexes.push(i)
    end
  end

  def pbViewOpponentCards(numCards)
    choice=0
    lastChoice=-1
    loop do
      if lastChoice!=choice
        y=HANDBASEY
        for i in 0...@opponentCardIndexes.length
          index = @opponentCardIndexes[i]
          @sprites["opponent#{index}"].bitmap =@opponentCardBitmaps[index]
          @sprites["opponent#{index}"].z=(i==choice) ? 4 : 2
          @sprites["opponent#{index}"].x=(i==choice) ? 
              OPPONENTHANDBASEX+22 : OPPONENTHANDBASEX
          @sprites["opponent#{index}"].y=y
          y+=HANDBONUSY
        end
        lastChoice=choice
      end
      if choice==-1
        break
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.repeat?(Input::DOWN)
        pbPlayCursorSE()
        choice+=1
        choice=0 if choice>=numCards
      elsif Input.repeat?(Input::UP)
        pbPlayCursorSE()
        choice-=1
        choice=numCards-1 if choice<0
      elsif Input.trigger?(Input::B)
        pbPlayCancelSE()
        choice=-1
      end
    end
    return choice
  end

  def pbPlayerChooseCard(numCards)
    pbWindowVisible(false)
    choice=0
    lastChoice=-1
    loop do
      if lastChoice!=choice
        y=HANDBASEY
        for i in 0...@cardIndexes.length
          @sprites["player#{@cardIndexes[i]}"].bitmap=@cardBitmaps[
              @cardIndexes[i]]
          @sprites["player#{@cardIndexes[i]}"].z=(i==choice) ? 4 : 2
          @sprites["player#{@cardIndexes[i]}"].x=(i==choice) ? 
              PLAYERHANDBASEX-32 : PLAYERHANDBASEX
          @sprites["player#{@cardIndexes[i]}"].y=y
          y+=HANDBONUSY
        end
        lastChoice=choice
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.repeat?(Input::DOWN)
        pbPlayCursorSE()
        choice+=1
        choice=0 if choice>=numCards
      elsif Input.repeat?(Input::UP)
        pbPlayCursorSE()
        choice-=1
        choice=numCards-1 if choice<0
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE()
        break
      elsif Input.trigger?(Input::A) && @battle.openHand
        pbPlayDecisionSE()
        pbViewOpponentCards(numCards)
        pbWindowVisible(false)
        choice=0
        lastChoice=-1
      end
    end
    return choice
  end

  def pbRefresh
    for i in 0...@battle.width*@battle.height
      x=i%@battle.width
      y=i/@battle.width
      if @boardSprites[i]
        owner=@battle.getOwner(x,y)
        @boardSprites[i].bitmap.dispose if @boardSprites[i].bitmap
        @boardSprites[i].bitmap = @boardCards[i] ? 
            @boardCards[i].createBitmap(owner, owner==2 ? @colorArrayOpponent : 
            @colorArrayPlayer) : TetraCard.createBlockBitmap
      end
    end
  end

  def pbEndPlaceCard(position, cardIndex)
    spriteIndex=@cardIndexes[cardIndex]
    boardIndex=position[1]*@battle.width+position[0]
    @boardSprites[boardIndex]=@sprites["player#{spriteIndex}"]
    @boardCards[boardIndex]=TetraCard.new(@playerCards[spriteIndex])
    pbRefresh
    @cardIndexes.delete_at(cardIndex)
    pbUpdateScore
  end

  def pbEndOpponentPlaceCard(position, cardIndex)
    spriteIndex=@opponentCardIndexes[cardIndex]
    boardIndex=position[1]*@battle.width+position[0]
    @boardSprites[boardIndex]=@sprites["opponent#{spriteIndex}"]
    @boardCards[boardIndex]=TetraCard.new(@opponentCards[spriteIndex])
    pbRefresh
    @opponentCardIndexes.delete_at(cardIndex)
    pbUpdateScore
  end
  
  def pbPutBlockCards(blockArray)
    for i in 0...blockArray.size
      spriteIndex=i
      boardIndex=blockArray[i]
      @sprites["block#{spriteIndex}"]=Sprite.new(@viewport)
      @sprites["block#{spriteIndex}"].z=2
      @sprites["block#{spriteIndex}"].x=FIELDBASEX + (
          boardIndex%@battle.width)*TetraCard::WIDTH
      @sprites["block#{spriteIndex}"].y=FIELDBASEY + (
          boardIndex/@battle.width)*TetraCard::HEIGHT
      @boardSprites[boardIndex]=@sprites["block#{spriteIndex}"]
    end  
    pbRefresh
  end

  def pbOpponentPlaceCard(tetraCard, position, cardIndex)
    y=HANDBASEY
    for i in 0...@opponentCardIndexes.length
      sprite=@sprites["opponent#{@opponentCardIndexes[i]}"]
      if i!=cardIndex
        sprite.z=2
        sprite.y=y
        sprite.x=OPPONENTHANDBASEX
        y+=HANDBONUSY
      else
        @opponentCardBitmaps[@opponentCardIndexes[i]]=tetraCard.createBitmap(
            2,@colorArrayOpponent)
        sprite.bitmap.dispose if sprite.bitmap
        sprite.bitmap=@opponentCardBitmaps[@opponentCardIndexes[i]]
        sprite.z=2
        sprite.x=FIELDBASEX + position[0]*TetraCard::WIDTH
        sprite.y=FIELDBASEY + position[1]*TetraCard::HEIGHT
      end
    end
  end

  def pbPlayerPlaceCard(card, cardIndex)
    choice=0
    boardX=0
    boardY=0
    doRefresh=true
    loop do
      if doRefresh
        y=HANDBASEY
        for i in 0...@cardIndexes.length
          if i!=cardIndex
            @sprites["player#{@cardIndexes[i]}"].z=2
            @sprites["player#{@cardIndexes[i]}"].y=y
            @sprites["player#{@cardIndexes[i]}"].x=PLAYERHANDBASEX
            y+=HANDBONUSY
          else
            @sprites["player#{@cardIndexes[i]}"].z=4
            @sprites["player#{@cardIndexes[i]}"].x=(
                FIELDBASEX + boardX*TetraCard::WIDTH)
            @sprites["player#{@cardIndexes[i]}"].y=(
                FIELDBASEY + boardY*TetraCard::HEIGHT)
          end
        end
        doRefresh=false
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.repeat?(Input::DOWN)
        pbPlayCursorSE()
        boardY+=1
        boardY=0 if boardY>=@battle.height
        doRefresh=true
      elsif Input.repeat?(Input::UP)
        pbPlayCursorSE()
        boardY-=1
        boardY=@battle.height-1 if boardY<0
        doRefresh=true
      elsif Input.repeat?(Input::LEFT)
        pbPlayCursorSE()
        boardX-=1
        boardX=@battle.width-1 if boardX<0
        doRefresh=true
      elsif Input.repeat?(Input::RIGHT)
        pbPlayCursorSE()
        boardX+=1
        boardX=0 if boardX>=@battle.width
        doRefresh=true
      elsif Input.trigger?(Input::B)
        return nil
      elsif Input.trigger?(Input::C)
        if @battle.isOccupied?(boardX,boardY)
          pbPlayBuzzerSE()
        else
          pbPlayDecisionSE()
          @sprites["player#{@cardIndexes[cardIndex]}"].z=2
          break
        end
      end
    end
    return [boardX,boardY] 
  end

  def pbChooseTetraCard(cardStorage)
    commands=[]
    chosenCards=[]
    for item in cardStorage
      commands.push(_INTL("{1} x{2}",PBSpecies.getName(item[0]),item[1]))
    end
    command=Window_CommandPokemonEx.newWithSize(
        commands,0,0,256,Graphics.height-64,@viewport)
    @sprites["helpwindow"].text=_INTL(
        "Choose {1} cards to use for this duel.",TetraScreen::HANDSIZE)
    preview=Sprite.new(@viewport)
    preview.z=4
    preview.x=276
    preview.y=60
    index=-1
    chosenSprites=[]
    for i in 0...TetraScreen::HANDSIZE
      @sprites["player#{i}"]=Sprite.new(@viewport)
      @sprites["player#{i}"].z=2
      @sprites["player#{i}"].x=PLAYERHANDBASEX
      @sprites["player#{i}"].y=HANDBASEY+HANDBONUSY*i
    end
    loop do
      Graphics.update
      Input.update
      pbUpdate
      command.update
      if command.index!=index
        preview.bitmap.dispose if preview.bitmap
        if command.index<cardStorage.length
          item=cardStorage[command.index]
          preview.bitmap=TetraCard.new(item[0]).createBitmap(
              1,@colorArrayPlayer)
        end
        index=command.index
      end
      if Input.trigger?(Input::B)
        if chosenCards.length>0
          item=chosenCards.pop
          @battle.pbAdd(cardStorage,item)
          commands=[]
          for item in cardStorage
            commands.push(_INTL("{1} x{2}",PBSpecies.getName(item[0]),item[1]))
          end
          command.commands=commands
          index=-1
        else
          pbPlayBuzzerSE()
        end
      elsif Input.trigger?(Input::C)
        if chosenCards.length==TetraScreen::HANDSIZE
          break
        end
        item=cardStorage[command.index]
        if !item || (@battle.pbQuantity(cardStorage,item[0])==0)
          pbPlayBuzzerSE()
        else
          pbPlayDecisionSE()
          sprite=@sprites["player#{chosenCards.length}"]
          sprite.bitmap.dispose if sprite.bitmap
          @cardBitmaps[chosenCards.length]=TetraCard.new(
              item[0]).createBitmap(1,@colorArrayPlayer)
          sprite.bitmap=@cardBitmaps[chosenCards.length]
          chosenCards.push(item[0])
          @battle.pbSubtract(cardStorage,item[0])
          commands=[]
          for item in cardStorage
            commands.push(_INTL("{1} x{2}",PBSpecies.getName(item[0]),item[1]))
          end
          command.commands=commands
          command.index=commands.length-1 if command.index>=commands.length
          index=-1
        end
      end
      if Input.trigger?(Input::C) || Input.trigger?(Input::B)
        for i in 0...TetraScreen::HANDSIZE
          @sprites["player#{i}"].visible=(i<chosenCards.length)
        end
        if chosenCards.length==TetraScreen::HANDSIZE
          @sprites["helpwindow"].text=_INTL(
              "{1} cards have been chosen.",TetraScreen::HANDSIZE)
          command.visible=false
          command.active=false
          preview.visible=false
        else
          @sprites["helpwindow"].text=_INTL(
              "Choose {1} cards to use for this duel.",TetraScreen::HANDSIZE)
          command.visible=true
          command.active=true
          preview.visible=true
        end
      end
    end
    command.dispose
    preview.bitmap.dispose if preview.bitmap
    preview.dispose
    return chosenCards
  end
  
  def pbAutoSetTetraCard(cardStorage)
    chosenCards=[]
    i=0
    for item in cardStorage
      item[1].times do
        @sprites["player#{i}"]=Sprite.new(@viewport)
        @sprites["player#{i}"].z=2
        @sprites["player#{i}"].x=PLAYERHANDBASEX
        @sprites["player#{i}"].y=HANDBASEY+HANDBONUSY*i
        #@sprites["player#{i}"].dispose if @sprites["player#{i}"].bitmap
        @cardBitmaps[chosenCards.length]=TetraCard.new(item[0]).createBitmap(
            1,@colorArrayPlayer)
        @sprites["player#{i}"].bitmap=@cardBitmaps[chosenCards.length]
        chosenCards.push(item[0])
        #@battle.pbSubtract(cardStorage,item[0])
        i+=1
      end
    end
    return chosenCards
  end
end

# Screen class for handling game logic
class TetraScreen
  attr_accessor :openHand,:countUnplayedCards
  attr_reader :width,:height

  def initialize(scene)
    @scene=scene
    @width              = 4
    @height             = 4
    @sameWins           = false
    @openHand           = false
    @wrapAround         = false
    @elements           = false
    @randomHand         = false
    @countUnplayedCards = false
    @disableTypeBonus   = false
    @trade              = 0
  end

  def board
    @board
  end

  def playerName
    @playerName
  end

  def opponentName
    @opponentName
  end

  def isOccupied?(x,y)
    return @board[y*@width+x].owner!=0
  end

  def getOwner(x,y)
    return @board[y*@width+x].owner
  end

  def getPanel(x,y)
    return @board[y*@width+x]
  end

  def pbQuantity(items,item)
    return ItemStorageHelper.pbQuantity(items,maxSize,item)
  end

  def pbAdd(items,item)
    return ItemStorageHelper.pbStoreItem(items,maxSize,maxPerSlot,item,1)
  end

  def pbSubtract(items,item)
    return ItemStorageHelper.pbDeleteItem(items,maxSize,
       item,1)
  end
     
  def maxSize
    return PBSpecies.getCount
  end

  def maxPerSlot
    return 99
  end

  def flipBoard(x,y,attackerParam=nil,recurse=false)
    panels=[x-1,y,x+1,y,x,y-1,x,y+1]
    panels[0]=(@wrapAround ? @width-1 : 0) if panels[0]<0 # left
    panels[2]=(@wrapAround ? 0 : @width-1) if panels[2]>@width-1 # right
    panels[5]=(@wrapAround ? @height-1 : 0) if panels[5]<0 # top
    panels[7]=(@wrapAround ? 0 : @height-1) if panels[7]>@height-1 # bottom
    attacker=attackerParam!=nil ? attackerParam : @board[y*@width+x]
    flips=[]
    return nil if attackerParam!=nil && @board[y*@width+x].owner!=0
    return nil if !attacker.card || attacker.owner==0
    for i in 0...4
      defenderX=panels[i*2]
      defenderY=panels[i*2+1]
      defender=@board[defenderY*@width+defenderX]
      next if !defender.card
      if attacker.owner!=defender.owner
        attack=attacker.attack(i)
        defense=defender.defense(i)
        if @elements
          # If attacker's type matches the tile's element, add
          # a bonus of 1 (only for original attacker, not combos)
          attack+=1 if !recurse && attacker.type==attacker.card.type
        end
        attack+=attacker.bonus(defender) if !@disableTypeBonus # Type bonus
        if attack>defense || (attack==defense && @sameWins)
          flips.push([defenderX,defenderY])
          if attackerParam==nil
            defender.owner=attacker.owner
            if @sameWins
              # Combo with the "sameWins" rule
              ret=flipBoard(defenderX,defenderY,nil,true)
              flips.concat(ret) if ret
            end
          else
            if @sameWins
              # Combo with the "sameWins" rule
              ret=flipBoard(defenderX,defenderY,attackerParam,true)
              flips.concat(ret) if ret
            end
          end
        end
      end
    end
    return flips
  end
  
  def blockPlacement(blockNumber=nil)
    blockNumber = rand(@width*@height-PLAYABLECARDS+1) if !blockNumber
    blockIndexArray=[]  
    while blockIndexArray.size<blockNumber
      index=rand(@board.size)
      blockIndexArray.push(index) if !blockIndexArray.include?(index)
    end
    blockArray2=[]
    # Checks if a square is alone. If so, redo the method (except the 
    # blockNumber). Uses a bidimensional array for easily manipulation
    for i in 0...@height
      blockArray2[i]=[]
      for j in 0...@width
        blockArray2[i][j]=blockIndexArray.include?(@height*i+j)
      end 
    end
    for i in 0...@height
      for j in 0...@width
        # If is a square, checks the 4 positions. Ignores the @wrapAround rule
        if !blockArray2[i][j] && ( 
            (i==0 || blockArray2[i-1][j]) && # Checks up
            (i==@height-1 || blockArray2[i+1][j]) && # Checks down
            (j==0 || blockArray2[i][j-1]) && # Checks left
            (j==@width-1 || blockArray2[i][j+1])) # Checks right
          blockPlacement(blockNumber)  
          return    
        end   
      end 
    end
    # End of checking
    for blockIndex in blockIndexArray
      square=TriadSquare.new
      square.owner=-1
      @board[blockIndex]=square  
    end  
    @scene.pbPutBlockCards(blockIndexArray)
  end  

# If pbStartScreen includes parameters, it should
# pass the parameters to pbStartScene.
  def pbStartScreen(opponentName,minLevel,maxLevel,
      rules=nil,oppdeck=nil,prize=nil)
    if minLevel<0 || minLevel>9
      raise _INTL("Minimum level must be 0 through 9.")
    end
    if maxLevel<0 || maxLevel>9
      raise _INTL("Maximum level must be 0 through 9.")
    end
    if maxLevel<minLevel
      raise _INTL("Maximum level shouldn't be less than the minimum level.")
    end
    if rules && rules.is_a?(Array) && rules.length>0
      for rule in rules
        @sameWins           = true if rule=="samewins"
        @openHand           = true if rule=="openhand"
        @wrapAround         = true if rule=="wrap"
        @elements           = true if rule=="elements"
        @randomHand         = true if rule=="randomhand"
        @countUnplayedCards = true if rule=="countunplayed"
        @disableTypeBonus   = true if rule=="disabletype" # Disable type bonus
        @trade              = 1    if rule=="direct"
        @trade              = 2    if rule=="winall"
      end
    end
    @tetraCards=[]
    count=0
    if USEPARTY
      for pokemon in $Trainer.party
        if !pokemon.isEgg?
          ItemStorageHelper.pbStoreItem(@tetraCards,
             maxSize,maxPerSlot,pokemon.species,1)
          count+=1
        end          
      end  
    else  
      if !$PokemonGlobal
        $PokemonGlobal=PokemonGlobalMetadata.new
      end
      for i in 0...$PokemonGlobal.triads.length
        item=$PokemonGlobal.triads[i]
        ItemStorageHelper.pbStoreItem(@tetraCards,
           maxSize,maxPerSlot,item[0],item[1]
        )
        count+=item[1] # Add item count to total count
      end
    end
    @board=[]
    @playerName=$Trainer ? $Trainer.name : "Trainer"
    @opponentName=opponentName
    for i in 0...@width*@height
      square=TriadSquare.new
      if @elements
        begin
          square.type=rand(PBTypes.maxValue+1)
        end until !PBTypes.isPseudoType?(square.type)
      end
      @board.push(square)
    end
    @scene.pbStartScene(self) # (param1, param2)
    # Check whether there are enough cards.
    if count<TetraScreen::HANDSIZE
      @scene.pbDisplayPaused(_INTL("You don't have enough cards."))
      @scene.pbEndScene
      return 0
    end
    # Set the player's cards.
    cards=[]
    if @randomHand   # Determine hand at random
      TetraScreen::HANDSIZE.times do
        randCard=@tetraCards[rand(@tetraCards.length)]
        pbSubtract(@tetraCards,randCard[0])
        cards.push(randCard[0]) 
      end
      @scene.pbShowPlayerCards(cards)
    else
      if USEPARTY && TetraScreen::HANDSIZE>6
        raise _INTL("HANDSIZE cannot be bigger than 6 when USEPARTY=true")
      elsif USEPARTY && TetraScreen::HANDSIZE==6
        # When TetraScreen::HANDSIZE it's 6 and USEPARTY, just copy the party
        cards=@scene.pbAutoSetTetraCard(@tetraCards)
      else  
        cards=@scene.pbChooseTetraCard(@tetraCards)
      end
    end
    # Set the opponent's cards.
    if oppdeck && oppdeck.is_a?(Array) && oppdeck.length>=TetraScreen::HANDSIZE
      # If the oppdeck is bigger that the handsize,
      # remove random pokémon until the size is right 
      while oppdeck.length>TetraScreen::HANDSIZE
        oppdeck.delete_at(rand(oppdeck.length))
      end  
      opponentCards=[]
      for i in oppdeck
        card=getID(PBSpecies,i)
        if card<=0
          @scene.pbDisplayPaused(
              _INTL("Opponent has an illegal card, \"{1}\".",i))
          @scene.pbEndScene
          return 0
        end
        opponentCards.push(card)
      end
    else
      candidates=[]
      while candidates.length<200
        card=rand(PBSpecies.maxValue)+1
        tetra=TetraCard.new(card)
        total=tetra.north+tetra.south+tetra.east+tetra.west
        # Add random species and its total point count
        candidates.push([card,total])
      end
      # sort by total point count
      candidates.sort!{|a,b| a[1]<=>b[1] }
      minIndex=minLevel*20
      maxIndex=maxLevel*20+20
      opponentCards=[]
      for i in 0...TetraScreen::HANDSIZE
        # generate random card based on level
        index=minIndex+rand(maxIndex-minIndex)
        opponentCards.push(candidates[index][0])
      end
    end
    originalCards=cards.clone
    originalOpponentCards=opponentCards.clone
    @scene.pbNotifyCards(cards.clone,opponentCards.clone)
    @scene.pbShowOpponentCards(opponentCards)
    blockPlacement
    @scene.pbDisplay(_INTL("Choosing the starting player..."))
    @scene.pbUpdateScore
    playerTurn=false
    if rand(2)==0
      @scene.pbDisplay(_INTL("{1} will go first.",@playerName))
      playerTurn=true
    else
      @scene.pbDisplay(_INTL("{1} will go first.",@opponentName))
      playerTurn=false
    end
    for i in 0...TetraScreen::PLAYABLECARDS
      position=nil
      tetraCard=nil
      cardIndex=0
      if playerTurn
        # Player's turn
        while !position
          cardIndex=@scene.pbPlayerChooseCard(cards.length)
          tetraCard=TetraCard.new(cards[cardIndex])
          position=@scene.pbPlayerPlaceCard(tetraCard,cardIndex)
        end
      else
        # Opponent's turn
        @scene.pbDisplay(_INTL("{1} is making a move...",@opponentName))    
        scores=[]
        for cardIndex in 0...opponentCards.length
          square=TriadSquare.new
          square.card=TetraCard.new(opponentCards[cardIndex])
          square.owner=2
          for i in 0...@width*@height
            x=i%@width
            y=i/@width
            square.type=@board[i].type
            flips=flipBoard(x,y,square)
            if flips!=nil
              scores.push([cardIndex,x,y,flips.length])
            end
          end
        end
        # Sort by number of flips
        scores.sort!{|a,b| 
           if b[3]==a[3]
             next [-1,1,0][rand(3)]
           else
             next b[3]<=>a[3]
           end
        } 
        scores=scores[0,opponentCards.length*3/2] # Get the best results
        if scores.length==0
          @scene.pbDisplay(_INTL("{1} can't move somehow...",@opponentName))
          playerTurn=!playerTurn
          continue
        end
        bestScore = scores[0][3]
        result=nil
        while !result
          result=scores[rand(scores.length)]
          # A random chance of not choosing the best result
          result=nil if result[3]<bestScore && rand(10)!=0
        end  
        cardIndex=result[0]
        tetraCard=TetraCard.new(opponentCards[cardIndex])
        position=[result[1],result[2]]
        @scene.pbOpponentPlaceCard(tetraCard,position,cardIndex)
      end
      boardIndex=position[1]*@width+position[0]
      board[boardIndex].card=tetraCard
      board[boardIndex].owner=playerTurn ? 1 : 2
      flipBoard(position[0],position[1])
      if playerTurn
        cards.delete_at(cardIndex)
        @scene.pbEndPlaceCard(position,cardIndex)
      else
        opponentCards.delete_at(cardIndex)
        @scene.pbEndOpponentPlaceCard(position,cardIndex)
      end
      playerTurn=!playerTurn
    end
    # Determine the winner
    playerCount=0
    opponentCount=0
    for i in 0...@width*@height
      playerCount+=1 if board[i].owner==1
      opponentCount+=1 if board[i].owner==2
    end
    if @countUnplayedCards
      playerCount+=cards.length
      opponentCount+=opponentCards.length
    end
    @scene.pbWindowVisible(true)
    result=0
    if playerCount==opponentCount
      @scene.pbDisplayPaused(_INTL("The game is a draw."))
      result=3
      if !USEPARTY
        case @trade
        when 1
          # Keep only cards of your color
          for card in originalCards
            $PokemonGlobal.triads.pbDeleteItem(card)
          end
          for i in cards
            $PokemonGlobal.triads.pbStoreItem(i)
          end
          for i in 0...@width*@height
            if board[i].owner==1
              $PokemonGlobal.triads.pbStoreItem(board[i].card.species)
            end
          end
          @scene.pbDisplayPaused(_INTL("Kept all cards of your color."))
        end
      end  
    elsif playerCount>opponentCount
      @scene.pbDisplayPaused(_INTL("{1} won against {2}.",
          @playerName,@opponentName))
      result=1
      if !USEPARTY
        if prize
          card=getID(PBSpecies,prize)
          if card>0 && $PokemonGlobal.triads.pbStoreItem(card)
            cardname=PBSpecies.getName(card)
            @scene.pbDisplayPaused(_INTL("Got opponent's {1} card.",cardname))
          end
        else
          case @trade
            when 0
              # Gain 1 random card from opponent's deck
              card=originalOpponentCards[rand(originalOpponentCards.length)]
              if $PokemonGlobal.triads.pbStoreItem(card)
                cardname=PBSpecies.getName(card)
                @scene.pbDisplayPaused(
                    _INTL("Got opponent's {1} card.",cardname))
              end
            when 1
              # Keep only cards of your color
              for card in originalCards
                $PokemonGlobal.triads.pbDeleteItem(card)
              end
              for i in cards
                $PokemonGlobal.triads.pbStoreItem(i)
              end
              for i in 0...@width*@height
                if board[i].owner==1
                  $PokemonGlobal.triads.pbStoreItem(board[i].card.species)
                end
              end
              @scene.pbDisplayPaused(_INTL("Kept all cards of your color."))
            when 2
              # Gain all opponent's cards
              for card in originalOpponentCards
                $PokemonGlobal.triads.pbStoreItem(card)
              end
              @scene.pbDisplayPaused(_INTL("Got all opponent's cards."))
          end
        end
      end  
    else
      @scene.pbDisplayPaused(
          _INTL("{1} lost against {2}.",@playerName,@opponentName))
      result=2
      if !USEPARTY
        case @trade
        when 0
          # Lose 1 random card from your deck
          card=originalCards[rand(originalCards.length)]
          $PokemonGlobal.triads.pbDeleteItem(card)
          cardname=PBSpecies.getName(card)
          @scene.pbDisplayPaused(_INTL("Opponent won your {1} card.",cardname))
        when 1
          # Keep only cards of your color
          for card in originalCards
            $PokemonGlobal.triads.pbDeleteItem(card)
          end
          for i in cards
            $PokemonGlobal.triads.pbStoreItem(i)
          end
          for i in 0...@width*@height
            if board[i].owner==1
              $PokemonGlobal.triads.pbStoreItem(board[i].card.species)
            end
          end
          @scene.pbDisplayPaused(
              _INTL("Kept all cards of your color.",cardname))
        when 2
          # Lose all your cards
          for card in originalCards
            $PokemonGlobal.triads.pbDeleteItem(card)
          end
          @scene.pbDisplayPaused(_INTL("Opponent won all your cards."))
        end  
      end
    end
    @scene.pbEndScene
    return result
  end
end

def pbTetraDuel(name,minLevel,maxLevel,rules=nil,oppdeck=nil,prize=nil,
    colorArrayPlayer=nil, colorArrayOpponent=nil)
  pbFadeOutInWithMusic(99999){
     scene=TetraScene.new(colorArrayPlayer,colorArrayOpponent)
     screen=TetraScreen.new(scene)
     screen.pbStartScreen(name,minLevel,maxLevel,rules,oppdeck,prize)
  }
end