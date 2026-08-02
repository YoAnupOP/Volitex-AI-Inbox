<script setup>
import { computed } from 'vue';
import BarChart from 'shared/components/charts/BarChart.vue';
const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const prepareData = sourceData => {
  var labels = [];
  var data = [];
  sourceData.forEach(item => {
    labels.push(item[0]);
    data.push(item[1]);
  });
  return {
    labels,
    datasets: [
      {
        type: 'bar',
        backgroundColor: 'rgb(31, 147, 255)',
        yAxisID: 'y',
        label: 'Conversations',
        data: data,
      },
    ],
  };
};

const chartData = computed(() => {
  return prepareData(props.componentData.chartData);
});

const { accountsCount, usersCount, inboxesCount, conversationsCount } =
  props.componentData;
</script>

<template>
  <div class="w-full h-full">
    <header class="main-content__header" role="banner">
      <h1 id="page-title" class="main-content__page-title text-slate-900 dark:text-slate-100">
        {{ 'Admin Dashboard' }}
      </h1>
    </header>

    <section class="main-content__body main-content__body--flush">
      <div class="report--list">
        <div class="report-card">
          <div class="metric text-slate-900 dark:text-slate-100">{{ accountsCount }}</div>
          <div class="text-slate-700 dark:text-slate-300">{{ 'Accounts' }}</div>
        </div>
        <div class="report-card">
          <div class="metric text-slate-900 dark:text-slate-100">{{ usersCount }}</div>
          <div class="text-slate-700 dark:text-slate-300">{{ 'Users' }}</div>
        </div>
        <div class="report-card">
          <div class="metric text-slate-900 dark:text-slate-100">{{ inboxesCount }}</div>
          <div class="text-slate-700 dark:text-slate-300">{{ 'Inboxes' }}</div>
        </div>
        <div class="report-card">
          <div class="metric text-slate-900 dark:text-slate-100">{{ conversationsCount }}</div>
          <div class="text-slate-700 dark:text-slate-300">{{ 'Conversations' }}</div>
        </div>
      </div>
    </section>
    <!-- eslint-disable vue/no-static-inline-styles -->
    <BarChart
      class="p-8 w-full"
      :collection="chartData"
      style="max-height: 500px"
    />
  </div>
</template>
