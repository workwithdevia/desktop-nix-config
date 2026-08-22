module.exports = {
    extends: ['@commitlint/config-conventional'],

    rules: {
        'type-enum': [
            2,
            'always',
            [
                'feat',
                'fix',
                'refactor',
                'chore',
                'docs',
                'test',
                'ci',
                'build',
                'perf',
            ],
        ],

        'scope-empty': [0],

        'subject-empty': [2, 'never'],

        'subject-full-stop': [2, 'never'],

        'header-max-length': [2, 'always', 100],
    },
};