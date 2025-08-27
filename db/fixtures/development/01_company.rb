company = Company.create(name: 'サンカクキカク')
company.departments.create(name: 'LP')
company.departments.create(name: 'DP')
company.departments.create(name: 'コーポレート')


company2 = Company.create(name: '森尾園')
company2.departments.create(name: '販売部')