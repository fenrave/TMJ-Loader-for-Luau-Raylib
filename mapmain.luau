local serde: _zune_serde_json = zune.serde.json
local fs: _zune_fs = zune.fs
local raylib = require("@raylib")

local lib = raylib.lib
local const = raylib.const
local struct = raylib.structs

local MapList = {}

local MapLoader = {}

export type Map = {
    TileInfo: {
        scale: vector,
        startposition: vector
    },
    Tiles: {[number]: {raylib.Rectangle}},
    TileIDs: {[number]: raylib.Rectangle},
    Textures: {[number]: raylib.Texture2D}
}

--[[+

@tm_formatting

TMX/TMJ texture atlases go from left -> right in increments of tile width,
moving down a tile height at the end of the current image slice.

Starts from 0.

TMX/TMJ have a "tilecount" thats always offset by +1. (39->40, for example)
So subtract 1.

TMX/TMJ files use numbered dictionaries in {} scopes, starting from 1.
Although most JSON formatting extensions will read them as "0."
Almost every instance of an array/table/dictionary will be defaulted to 1 in Lua/Luau.

+]]--

function MapLoader:LoadMap(Map: string, Atlas: string): {}
    
    local Raw: string = fs.readFile(Map)
    
    local MapData = serde.decode(Raw)


    local tilemap = MapData["layers"][1]["data"]

    local Mapped: Map = {
        TileInfo = {},
        Tiles = {},
        TileIDs = {},
        Textures = {}
    }

    local width: number = MapData["width"]
    local height: number = MapData["height"]
    

    local tilewidth: number = MapData["tilewidth"]
    local tileheight: number = MapData["tileheight"]
    local tilesets: {[string]: any} = MapData["tilesets"]
    local tilecount: number = tilesets[1]["tilecount"]

    if not tilecount then
        tilecount = 2
    end; tilecount -= 1

    local atlascolumns: number = tilesets[1]["columns"]
    local imageheight: number = tilesets[1]["imageheight"]
    local imagewidth: number = tilesets[1]["imagewidth"]

    local num: number = 0
    local cX: number = 0
    local cY: number = 0

    local AtlasImg = lib.LoadImage(Atlas)
    

    local Texture: raylib.Texture2D = lib.LoadTextureFromImage(AtlasImg)

    lib.SetTextureFilter(Texture, 0)
    

    Mapped.Textures[0] = Texture
    
    buffer.writei32(Texture, 16, 10)

    lib.GenTextureMipmaps(Texture)


    --Destinations
    for Index: number, Tile: number in tilemap do
        if num == width then
            num = 0; cX = 0; cY += tileheight
        end; num += 1

        local Rect: raylib.Rectangle = struct.Rectangle:new{
            x = cX,
            y = cY,
            width = tilewidth,
            height = tileheight
        }


        if not Mapped.Tiles[Tile] then
            Mapped.Tiles[Tile] = {}
        end

        if not Mapped.TileIDs[Tile] then
            Mapped.TileIDs[Tile] = nil
        end
        
        table.insert(Mapped.Tiles[Tile], Rect)

        cX += tilewidth
    end

    cX = 1; cY = 1; num = 0

    --Source Tiles
    for i: number = 1, tilecount, 1 do
        if num == atlascolumns then
            num = 0; cX = 1; cY += tileheight + 1
        end; num += 1

        local SourceRect = struct.Rectangle:new{
            x = math.floor(cX + 1),
            y = math.floor(cY + 1),
            width = tilewidth - 1,
            height = tileheight - 1
        }

        Mapped.TileIDs[i] = SourceRect

        
        cX += tilewidth + 1

    end


    Mapped.TileInfo = {
        startposition = vector.zero,
        scale = vector.create(tilewidth, tileheight)
    }
    
    return Mapped, Texture
end

return MapLoader