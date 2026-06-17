import { ConfigLineSettings, HiddenSettings } from "@metaplex-foundation/mpl-core-candy-machine";
import fs from 'node:fs';
import path from 'node:path';
import { CandyMachineConfig, CandyMachineAssetCache, CandyMachineAssetCacheItem } from './types.js';
import validateAssetsFolder from './validateAssetsFolder.js';

export const MAX_GROUP_LABEL_LENGTH = 6;

export const defaultConfigLineSettings: ConfigLineSettings = {
    prefixName: '',
    nameLength: 32,
    prefixUri: '',
    uriLength: 200,
    isSequential: false,
}

export const defaultHiddenSettings: HiddenSettings = {
    name: '',
    uri: '',
    hash: new Uint8Array(),
}

// Common file path utilities
export const getCmPaths = (directory?: string) => {
    const baseDir = directory || process.cwd();
    return {
        configPath: path.join(baseDir, 'cm-config.json'),
        assetCachePath: path.join(baseDir, 'asset-cache.json'),
        assetsDir: path.join(baseDir, 'assets'),
        baseDir
    };
};

// Common file reading utilities
export const readCmConfig = (directory?: string): CandyMachineConfig => {
    const { configPath } = getCmPaths(directory);
    
    if (!fs.existsSync(configPath)) {
        throw new Error(`Config file not found at ${configPath}`);
    }
    
    return JSON.parse(fs.readFileSync(configPath, 'utf8')) as CandyMachineConfig;
};

export const readAssetCache = (directory?: string): CandyMachineAssetCache => {
    const { assetCachePath } = getCmPaths(directory);
    
    if (!fs.existsSync(assetCachePath)) {
        throw new Error(`Asset cache file not found at ${assetCachePath}`);
    }
    
    return JSON.parse(fs.readFileSync(assetCachePath, 'utf8')) as CandyMachineAssetCache;
};

export const writeAssetCache = (assetCache: CandyMachineAssetCache, directory?: string): void => {
    const { assetCachePath } = getCmPaths(directory);
    fs.writeFileSync(assetCachePath, JSON.stringify(assetCache, null, 2));
};

export const writeCmConfig = (config: CandyMachineConfig, directory?: string): void => {
    const { configPath } = getCmPaths(directory);
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
};

// Create initial asset cache from assets folder
export const createInitialAssetCache = async (directory?: string): Promise<CandyMachineAssetCache> => {
    const { assetsDir } = getCmPaths(directory);
    
    if (!fs.existsSync(assetsDir)) {
        throw new Error(`Assets directory not found at ${assetsDir}`);
    }
    
    let validation = await validateAssetsFolder(assetsDir);
    if ('error' in validation) {
        // If there are no local images but JSON files exist, allow JSON-only mode
        if (validation.error.includes('No image files')) {
            validation = await validateAssetsFolder(assetsDir, { allowJsonOnly: true });
            if ('error' in validation) {
                throw new Error(validation.error);
            }
        } else {
            throw new Error(validation.error);
        }
    }
    
    const assetCache: CandyMachineAssetCache = {
        assetItems: {}
    };
    
    for (let index = 0; index < validation.jsonFiles.length; index++) {
        const jsonFile = validation.jsonFiles[index];
        const imageFile = validation.imageFiles[index];
        const animationFile = validation.animationFiles?.[index];

        // Read the JSON file to get the name and possibly a remote image URI
        const jsonPath = path.join(assetsDir, jsonFile);
        const jsonContent = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
        const name = jsonContent.name;

        // If there's no local image file but the JSON references a remote image (arweave/ipfs/http),
        // store that URI in the asset cache `image` field so upload logic can detect and skip it.
        const isRemoteUri = (value?: string) => {
            if (!value) return false
            return /^(https?:|ipfs:|ar:|data:)/i.test(value)
        }

        const imageValue = imageFile ? imageFile : (isRemoteUri(jsonContent.image) ? jsonContent.image : undefined)

        const assetCacheItem: CandyMachineAssetCacheItem = {
            name,
            image: imageValue,
            animation: animationFile,
            json: jsonFile,
            loaded: false,
        };

        // If the image is already a remote URI, populate imageUri and imageType so
        // storage validation won't require uploading or re-uploading the image.
        if (!imageFile && isRemoteUri(jsonContent.image)) {
            assetCacheItem.imageUri = jsonContent.image
            try {
                const fileEntry = jsonContent.properties?.files?.[0]
                if (fileEntry && fileEntry.type) {
                    assetCacheItem.imageType = fileEntry.type
                }
            } catch (e) {
                // ignore
            }
        }
        
        assetCache.assetItems[index] = assetCacheItem;
    }
    
    return assetCache;
};

// Summarize the load state of an asset cache after an insert run
export const summarizeAssetCache = (assetCache: CandyMachineAssetCache) => {
    const totalItems = Object.keys(assetCache.assetItems).length;
    const loadedItems = Object.values(assetCache.assetItems).filter(item => item.loaded).length;
    const failedItems = totalItems - loadedItems;
    return { totalItems, loadedItems, failedItems };
};

// Common validation utilities
export const validateCmDirectory = (directory?: string): void => {
    const { assetsDir } = getCmPaths(directory);
    
    if (!fs.existsSync(assetsDir)) {
        throw new Error(`Assets directory not found at ${assetsDir}`);
    }
};

export const validateCmConfig = (config: CandyMachineConfig): void => {
    if (config.candyMachineId) {
        throw new Error('Candy machine already exists. Delete the candy machine ID from the config file to create a new one');
    }
    
    if (!config.config.collection) {
        throw new Error('No collection found. Please create a collection first and add it to the config file');
    }
    
    if (config.config.itemsAvailable <= 0) {
        throw new Error('Items available must be greater than 0');
    }
};

// Common config line settings logic
export const getConfigLineSettings = (candyMachineConfig: CandyMachineConfig) => {
    if (candyMachineConfig.config.hiddenSettings) {
        return {
            hiddenSettings: candyMachineConfig.config.hiddenSettings
        };
    }

    if (candyMachineConfig.config.configLineSettings) {
        return { configLineSettings: candyMachineConfig.config.configLineSettings };
    }

    return { configLineSettings: defaultConfigLineSettings };
};