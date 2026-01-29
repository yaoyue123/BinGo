/**
 * BinGo Core Library
 *
 * Utilities for binary vulnerability analysis
 *
 * @license Apache-2.0
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

/**
 * Default BinGo configuration
 */
const DEFAULT_CONFIG = {
    joern: {
        max_heap_size: 'auto',
        auto_detect: true,
        timeout_minutes: 60
    },
    analysis: {
        min_cpg_nodes: 100,
        timeout_minutes: 60
    },
    audit: {
        strict_mode: true,
        require_all_5_checks: true
    },
    reporting: {
        include_poc: true,
        severity_threshold: 'low'
    }
};

/**
 * Load BinGo configuration from file
 *
 * @param {string} configPath - Path to config file (optional)
 * @returns {object} Parsed configuration object
 */
export function loadConfig(configPath) {
    // Check default locations
    const defaultPaths = [
        configPath,
        './bingo-config.json',
        path.join(process.env.HOME || '', '.config', 'bingo', 'config.json'),
        path.join(process.env.HOME || '', '.bingo', 'config.json')
    ].filter(Boolean);

    for (const configFile of defaultPaths) {
        if (configFile && fs.existsSync(configFile)) {
            try {
                const content = fs.readFileSync(configFile, 'utf8');
                const userConfig = JSON.parse(content);
                return { ...DEFAULT_CONFIG, ...userConfig };
            } catch (error) {
                console.warn(`Warning: Failed to parse config from ${configFile}: ${error.message}`);
            }
        }
    }

    return DEFAULT_CONFIG;
}

/**
 * Find Joern installation directory
 *
 * @returns {string|null} Path to Joern installation or null if not found
 */
export function findJoern() {
    // Check environment variable first
    if (process.env.JOERN_HOME) {
        const joernPath = path.join(process.env.JOERN_HOME, 'joern');
        if (fs.existsSync(joernPath)) {
            return process.env.JOERN_HOME;
        }
    }

    // Check common installation paths
    const commonPaths = [
        '~/joern',
        path.join(process.env.HOME || '', 'joern'),
        '~/bin/joern',
        path.join(process.env.HOME || '', 'bin', 'joern'),
        '/opt/joern',
        '/usr/local/joern',
        '/usr/local/bin/joern'
    ].filter(Boolean);

    for (const p of commonPaths) {
        const expanded = p.replace(/^~/, process.env.HOME || '');
        if (fs.existsSync(expanded)) {
            return expanded;
        }
    }

    // Check if joern is in PATH
    try {
        const joernLocation = execSync('which joern', { encoding: 'utf8', stdio: 'pipe' }).trim();
        if (joernLocation) {
            return path.dirname(joernLocation);
        }
    } catch {
        // joern not in PATH
    }

    return null;
}

/**
 * Validate Joern installation
 *
 * @param {string} joernPath - Path to Joern installation
 * @returns {object} Validation result with {valid, version, error}
 */
export function validateJoern(joernPath) {
    const joernExec = path.join(joernPath, 'joern');

    if (!fs.existsSync(joernExec)) {
        return { valid: false, version: null, error: 'joern executable not found' };
    }

    try {
        const version = execSync(`${joernExec} --version`, { encoding: 'utf8', stdio: 'pipe', timeout: 5000 }).trim();
        return { valid: true, version, error: null };
    } catch (error) {
        return { valid: false, version: null, error: error.message };
    }
}

/**
 * Parse binary info JSON
 *
 * @param {string} jsonPath - Path to binary_info.json file
 * @returns {object} Parsed binary info
 */
export function parseBinaryInfo(jsonPath) {
    if (!fs.existsSync(jsonPath)) {
        throw new Error(`Binary info not found: ${jsonPath}`);
    }

    const content = fs.readFileSync(jsonPath, 'utf8');
    return JSON.parse(content);
}

/**
 * Parse vulnerability findings JSON
 *
 * @param {string} jsonPath - Path to vulnerabilities JSON file
 * @returns {object} Parsed vulnerabilities
 */
export function parseVulnerabilities(jsonPath) {
    if (!fs.existsSync(jsonPath)) {
        throw new Error(`Vulnerabilities file not found: ${jsonPath}`);
    }

    const content = fs.readFileSync(jsonPath, 'utf8');
    return JSON.parse(content);
}

/**
 * Get BinGo skills directory
 *
 * @returns {string} Path to skills directory
 */
export function getSkillsRoot() {
    // Assume this file is at lib/bingo-core.js
    const libDir = path.dirname(new URL(import.meta.url).pathname);
    const pluginRoot = path.dirname(libDir);
    return path.join(pluginRoot, 'skills');
}

/**
 * List all BinGo skills
 *
 * @returns {Array<{name: string, path: string}>} List of available skills
 */
export function listSkills() {
    const skillsRoot = getSkillsRoot();
    const skills = [];

    if (!fs.existsSync(skillsRoot)) {
        return skills;
    }

    const entries = fs.readdirSync(skillsRoot, { withFileTypes: true });

    for (const entry of entries) {
        if (entry.isDirectory()) {
            const skillFile = path.join(skillsRoot, entry.name, 'SKILL.md');
            if (fs.existsSync(skillFile)) {
                skills.push({
                    name: entry.name,
                    path: skillFile
                });
            }
        }
    }

    return skills;
}

/**
 * Format Joern heap size argument
 *
 * @param {string} heapSize - Heap size config ('auto', '4G', '8G', etc.)
 * @param {number} defaultGB - Default GB to use if 'auto'
 * @returns {string} JVM -Xmx argument
 */
export function formatHeapSize(heapSize, defaultGB = 4) {
    if (heapSize === 'auto') {
        const systemMemoryGB = Math.floor(require('os').totalmem() / (1024 ** 3));
        const allocated = Math.max(2, Math.min(systemMemoryGB - 2, defaultGB));
        return `-Xmx${allocated}G`;
    }
    return `-Xmx${heapSize}`;
}

export {
    loadConfig as default,
    DEFAULT_CONFIG
};
